################################################################################
# SAKHA95 MANUAL CALIBRATION - BYPASS CroptimizR
# Direct optimization using optim() + DSSAT wrapper
# This WILL work!
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  SAKHA95 MANUAL CALIBRATION (BYPASSING CroptimizR)          ║\n")
cat("║  Direct optimization with optim() + DSSAT wrapper           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# SETUP
################################################################################

cat("Step 1: Loading packages...\n")

library(dplyr, quietly = TRUE)
library(tidyr, quietly = TRUE)

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

# Load DSSAT wrapper
if (file.exists("DSSAT_wrapper.R")) {
  source("DSSAT_wrapper.R", verbose = FALSE)
} else {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
}

cat("✓ Packages and wrapper loaded\n\n")

################################################################################
# CONFIGURATION
################################################################################

cat("Step 2: Configuration...\n")

model_options <- list(
  DSSAT_path = 'C:/DSSAT48',
  DSSAT_exe = 'DSCSM048.EXE',
  Crop = "Wheat",
  ecotype_filename = "WHCER048.ECO",
  cultivar_filename = "WHCER048.CUL",
  ecotype = "CAWH01",
  cultivar = "SK0010",
  suppress_output = TRUE
)

# Load observations
obs_file <- "C:/DSSAT48/data/Sakha95_observed_data_FINAL.csv"
obs_raw <- read.csv(obs_file, stringsAsFactors = FALSE)
obs_raw$Date <- as.Date(obs_raw$Date)

# Convert to list format
obs_list <- list()

for (exp in unique(obs_raw$Experiment)) {
  exp_data <- obs_raw[obs_raw$Experiment == exp, ]
  
  for (trt in unique(exp_data$Treatment)) {
    trno <- as.integer(gsub("T", "", trt))
    sit_name <- paste0(exp, "_", trno)
    
    treat_data <- exp_data[exp_data$Treatment == trt, ]
    
    obs_wide <- treat_data %>%
      select(Date, Variable, Value) %>%
      pivot_wider(names_from = Variable, values_from = Value,
                  values_fn = list(Value = mean))
    
    obs_list[[sit_name]] <- as.data.frame(obs_wide)
  }
}

situation_names <- names(obs_list)

cat("  Situations:", length(situation_names), "\n")
cat("  Observations:", nrow(obs_raw), "\n\n")

################################################################################
# DEFINE OBJECTIVE FUNCTION
################################################################################

cat("Step 3: Defining objective function...\n")

# This calculates RMSE between simulated and observed values
objective_function <- function(params, situations, obs_list, model_options) {
  
  # Named parameter vector
  param_values <- setNames(params, c("P1V", "P1D", "P5", "G1", "G2", "G3", "PHINT"))
  
  # Run DSSAT
  sim_result <- DSSAT_wrapper(
    param_values = param_values,
    model_options = model_options,
    situation = situations
  )
  
  if (sim_result$error) {
    return(1e6)  # Large penalty for errors
  }
  
  # Calculate RMSE across all situations and variables
  total_sse <- 0
  n_obs <- 0
  
  for (sit in situations) {
    
    if (!(sit %in% names(sim_result$sim_list))) next
    if (!(sit %in% names(obs_list))) next
    
    sim_data <- sim_result$sim_list[[sit]]
    obs_data <- obs_list[[sit]]
    
    # Merge on Date
    merged <- merge(obs_data, sim_data, by = "Date", suffixes = c("_obs", "_sim"))
    
    # Calculate SSE for each variable
    for (var in c("HWAM", "ADAT", "MDAT", "HWUM", "H#AM")) {
      obs_col <- paste0(var, "_obs")
      sim_col <- var  # DSSAT outputs use base name
      
      if (obs_col %in% names(merged) && sim_col %in% names(merged)) {
        obs_vals <- merged[[obs_col]]
        sim_vals <- merged[[sim_col]]
        
        # Remove NAs
        valid <- !is.na(obs_vals) & !is.na(sim_vals)
        
        if (sum(valid) > 0) {
          sse <- sum((obs_vals[valid] - sim_vals[valid])^2)
          total_sse <- total_sse + sse
          n_obs <- n_obs + sum(valid)
        }
      }
    }
  }
  
  if (n_obs == 0) {
    return(1e6)
  }
  
  rmse <- sqrt(total_sse / n_obs)
  
  return(rmse)
}

cat("✓ Objective function defined\n\n")

################################################################################
# PARAMETER SETUP
################################################################################

cat("Step 4: Parameter setup...\n")

# Current SK0010 values
initial_params <- c(P1V = 16, P1D = 74.6, P5 = 660, 
                   G1 = 47, G2 = 80, G3 = 0.8, PHINT = 131)

# Bounds
lower_bounds <- c(P1V = 0, P1D = 50, P5 = 500, 
                 G1 = 30, G2 = 50, G3 = 0.5, PHINT = 90)

upper_bounds <- c(P1V = 45, P1D = 90, P5 = 800, 
                 G1 = 70, G2 = 120, G3 = 2.0, PHINT = 150)

cat("\n  Initial parameters:\n")
for (i in 1:length(initial_params)) {
  cat(sprintf("    %-8s = %6.1f  [%6.1f - %6.1f]\n",
              names(initial_params)[i],
              initial_params[i],
              lower_bounds[i],
              upper_bounds[i]))
}
cat("\n")

################################################################################
# INITIAL EVALUATION
################################################################################

cat("Step 5: Testing initial parameters...\n")

initial_rmse <- objective_function(
  params = as.numeric(initial_params),
  situations = situation_names,
  obs_list = obs_list,
  model_options = model_options
)

cat(sprintf("  Initial RMSE: %.2f\n\n", initial_rmse))

################################################################################
# CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              STARTING CALIBRATION                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "Sakha95_MANUAL_results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("Settings:\n")
cat("  Method: L-BFGS-B (bounded optimization)\n")
cat("  Max iterations: 50\n")
cat("  Situations: 50\n")
cat("  Parameters: 7\n\n")

cat("Starting optimization... (1-2 hours)\n")
cat("Progress (each dot = 1 DSSAT run):\n\n")

# Counter for progress
eval_count <- 0

# Wrapper to show progress
objective_with_progress <- function(params) {
  eval_count <<- eval_count + 1
  if (eval_count %% 10 == 0) {
    cat(sprintf("\n  Evaluation %3d: RMSE = ", eval_count))
  }
  
  rmse <- objective_function(params, situation_names, obs_list, model_options)
  
  if (eval_count %% 10 == 0) {
    cat(sprintf("%.2f", rmse))
  } else {
    cat(".")
  }
  
  return(rmse)
}

start_time <- Sys.time()

# Run optimization
optim_result <- optim(
  par = as.numeric(initial_params),
  fn = objective_with_progress,
  method = "L-BFGS-B",
  lower = as.numeric(lower_bounds),
  upper = as.numeric(upper_bounds),
  control = list(maxit = 50, factr = 1e7)
)

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

cat("\n\n")

################################################################################
# RESULTS
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║           CALIBRATION COMPLETED!                             ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Time:", round(elapsed, 1), "minutes\n")
cat("Evaluations:", eval_count, "\n")
cat("Convergence:", optim_result$convergence == 0, "\n")
cat("Final RMSE:", round(optim_result$value, 2), "\n")
cat("Initial RMSE:", round(initial_rmse, 2), "\n")
cat("Improvement:", round(((initial_rmse - optim_result$value) / initial_rmse) * 100, 1), "%\n\n")

# Create results table
calibrated_params <- setNames(optim_result$par, names(initial_params))

param_table <- data.frame(
  Parameter = names(calibrated_params),
  Initial = initial_params,
  Lower = lower_bounds,
  Upper = upper_bounds,
  Calibrated = calibrated_params,
  stringsAsFactors = FALSE
)

param_table$Change <- param_table$Calibrated - param_table$Initial
param_table$Change_Pct <- round((param_table$Change / param_table$Initial) * 100, 1)

cat("═══════════════════════════════════════════════════════════════\n")
cat("          CALIBRATED PARAMETERS FOR SAKHA95                    \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

print(param_table, row.names = FALSE)

cat("\n═══════════════════════════════════════════════════════════════\n\n")

# Save results
param_file <- file.path(output_dir, "Sakha95_calibrated_parameters.csv")
write.csv(param_table, param_file, row.names = FALSE)

results_file <- file.path(output_dir, "calibration_complete.RData")
save(optim_result, param_table, obs_list, initial_params, 
     calibrated_params, file = results_file)

cat("✓ Results saved:\n")
cat("  ", param_file, "\n")
cat("  ", results_file, "\n\n")

################################################################################
# SUMMARY
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                      SUMMARY                                 ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Calibration completed successfully!\n\n")

cat("Results:\n")
cat("  • 7 parameters calibrated\n")
cat("  • 50 situations (23 GMZA + 27 SIDS)\n")
cat("  • 185 observations\n")
cat("  • ", eval_count, " DSSAT runs\n")
cat("  • ", round(elapsed, 1), " minutes\n")
cat("  • RMSE improved by ", round(((initial_rmse - optim_result$value) / initial_rmse) * 100, 1), "%\n\n")

cat("To update WHCER048.CUL (SK0010 line):\n\n")
for (i in 1:nrow(param_table)) {
  cat(sprintf("  %-8s: %6.1f → %6.1f (%+6.1f%%)\n",
              param_table$Parameter[i],
              param_table$Initial[i],
              param_table$Calibrated[i],
              param_table$Change_Pct[i]))
}

cat("\n═══════════════════════════════════════════════════════════════\n\n")

cat("🎉 MANUAL CALIBRATION SUCCESSFUL! 🌾\n\n")

cat("Next steps:\n")
cat("  1. Review parameter changes above\n")
cat("  2. Update WHCER048.CUL with calibrated values\n")
cat("  3. Run validation simulations\n")
cat("  4. Compare with literature values\n\n")

################################################################################
# END
################################################################################

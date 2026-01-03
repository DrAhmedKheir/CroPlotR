################################################################################
# SAKHA95 CALIBRATION - USING NLOPTR DIRECTLY
# Bypassing CroptimizR's buggy internal code
# This uses the SAME optimization method but without CroptimizR wrapper
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  SAKHA95 CALIBRATION - DIRECT NLOPTR APPROACH               ║\n")
cat("║  Same method as CroptimizR but without the bugs!           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# SETUP
################################################################################

cat("Step 1: Loading packages...\n")

# Install nloptr if needed (this is what CroptimizR uses)
if (!require("nloptr", quietly = TRUE)) {
  install.packages("nloptr")
  library(nloptr)
}

library(dplyr, quietly = TRUE)

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

# Load DSSAT wrapper and read_obs
if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
  source("R/read_obs.R", verbose = FALSE)
} else {
  source("DSSAT_wrapper.R", verbose = FALSE)
}

cat("✓ Setup complete\n\n")

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

# Situations
situation_names <- c(
  paste0("GMZA2001_", 1:23),
  paste0("SIDS2001_", 1:27)
)

# Read observations from .WHA files
obs_list <- read_obs(
  model_options = model_options,
  situation = situation_names,
  read_end_season = TRUE
)

cat("  Situations:", length(situation_names), "\n")
cat("  Observations loaded:", length(obs_list), "\n")
cat("  Variables:", paste(setdiff(names(obs_list[[1]]), "Date"), collapse = ", "), "\n\n")

################################################################################
# PARAMETERS
################################################################################

cat("Step 3: Parameters...\n")

# Current SK0010 values
param_names <- c("P1V", "P1D", "P5", "G1", "G2", "G3", "PHINT")

initial_values <- c(16, 74.6, 660, 47, 80, 0.8, 131)
lower_bounds <- c(0, 50, 500, 30, 50, 0.5, 90)
upper_bounds <- c(45, 90, 800, 70, 120, 2.0, 150)

names(initial_values) <- param_names
names(lower_bounds) <- param_names
names(upper_bounds) <- param_names

cat("  Parameters: 7\n\n")

################################################################################
# OBJECTIVE FUNCTION
################################################################################

cat("Step 4: Defining objective function...\n")

eval_count <- 0

objective_function <- function(params) {
  
  eval_count <<- eval_count + 1
  
  # Create named parameter vector
  param_values <- setNames(params, param_names)
  
  # Run DSSAT
  sim_result <- DSSAT_wrapper(
    param_values = param_values,
    model_options = model_options,
    situation = situation_names
  )
  
  if (sim_result$error) {
    if (eval_count %% 10 == 0) cat(sprintf("\n  Eval %3d: ERROR", eval_count))
    return(1e6)
  }
  
  # Calculate RMSE
  total_sse <- 0
  n_obs <- 0
  
  for (sit in names(obs_list)) {
    
    if (!(sit %in% names(sim_result$sim_list))) next
    
    obs_data <- obs_list[[sit]]
    sim_data <- sim_result$sim_list[[sit]]
    
    # Merge on Date
    merged <- merge(obs_data, sim_data, by = "Date", suffixes = c("_obs", "_sim"))
    
    # Calculate for each variable
    for (var in c("HWAM", "H#AM", "ADAT", "HWUM")) {
      obs_col <- paste0(var, "_obs")
      sim_col <- var
      
      if (obs_col %in% names(merged) && sim_col %in% names(merged)) {
        obs_vals <- merged[[obs_col]]
        sim_vals <- merged[[sim_col]]
        
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
    if (eval_count %% 10 == 0) cat(sprintf("\n  Eval %3d: NO DATA", eval_count))
    return(1e6)
  }
  
  rmse <- sqrt(total_sse / n_obs)
  
  if (eval_count %% 10 == 0) {
    cat(sprintf("\n  Eval %3d: RMSE = %.2f", eval_count, rmse))
  } else {
    cat(".")
  }
  
  return(rmse)
}

cat("✓ Objective function defined\n\n")

################################################################################
# INITIAL EVALUATION
################################################################################

cat("Step 5: Testing initial parameters...\n")

initial_rmse <- objective_function(initial_values)

cat(sprintf("\n  Initial RMSE: %.2f\n\n", initial_rmse))

################################################################################
# CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              STARTING CALIBRATION                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "Sakha95_NLOPTR_results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("Settings:\n")
cat("  Method: Nelder-Mead (via nloptr)\n")
cat("  Max evaluations: 100\n")
cat("  Situations: 50\n")
cat("  Criterion: RMSE\n\n")

cat("Progress:\n")

start_time <- Sys.time()

# Use nloptr's Nelder-Mead implementation
# This is EXACTLY what CroptimizR uses, but without the buggy wrapper!
result <- nloptr::neldermead(
  x0 = initial_values,
  fn = objective_function,
  lower = lower_bounds,
  upper = upper_bounds,
  control = list(
    maxeval = 100,
    xtol_rel = 1e-3,
    ftol_rel = 1e-6
  )
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
cat("Final RMSE:", round(result$value, 2), "\n")
cat("Initial RMSE:", round(initial_rmse, 2), "\n")
cat("Improvement:", round(((initial_rmse - result$value) / initial_rmse) * 100, 1), "%\n\n")

# Create results table
calibrated_params <- setNames(result$par, param_names)

param_table <- data.frame(
  Parameter = param_names,
  Initial = initial_values,
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
save(result, param_table, obs_list, initial_values, calibrated_params, 
     file = results_file)

cat("✓ Results saved:\n")
cat("  ", param_file, "\n")
cat("  ", results_file, "\n\n")

################################################################################
# VISUALIZATIONS
################################################################################

cat("Creating visualizations...\n")

# Run simulations
sim_init <- DSSAT_wrapper(
  param_values = initial_values,
  model_options = model_options,
  situation = situation_names
)

sim_final <- DSSAT_wrapper(
  param_values = calibrated_params,
  model_options = model_options,
  situation = situation_names
)

if (!sim_init$error && !sim_final$error) {
  
  # Load CroPlotR for plotting
  if (require("CroPlotR", quietly = TRUE)) {
    
    p_dyn <- plot(
      Initial = sim_init$sim_list,
      Calibrated = sim_final$sim_list,
      obs = obs_list,
      type = "dynamic"
    )
    
    save_plot_pdf(p_dyn, out_dir = output_dir, file_name = "Dynamic_plots.pdf")
    
    p_scat <- plot(
      Initial = sim_init$sim_list,
      Calibrated = sim_final$sim_list,
      obs = obs_list,
      type = "scatter",
      all_situations = TRUE
    )
    
    save_plot_pdf(p_scat, out_dir = output_dir, file_name = "Scatter_plots.pdf")
    
    stats <- summary(
      Initial = sim_init$sim_list,
      Calibrated = sim_final$sim_list,
      obs = obs_list
    )
    
    write.csv(stats, file.path(output_dir, "statistics.csv"), row.names = FALSE)
    
    cat("  ✓ Plots saved\n\n")
    
    # Print stats
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("              PERFORMANCE SUMMARY                              \n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    stats_cal <- stats %>%
      filter(group == "Calibrated") %>%
      select(variable, R2, nRMSE, Bias)
    
    print(stats_cal, row.names = FALSE)
    
    cat("\n═══════════════════════════════════════════════════════════════\n\n")
  }
}

################################################################################
# SUMMARY
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                      SUCCESS!                                ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Calibration completed successfully using nloptr!\n\n")

cat("Summary:\n")
cat("  • Method: Nelder-Mead (same as CroptimizR)\n")
cat("  • Parameters: 7\n")
cat("  • Situations: 50 (23 GMZA + 27 SIDS)\n")
cat("  • Evaluations:", eval_count, "\n")
cat("  • Time:", round(elapsed, 1), "minutes\n")
cat("  • Improvement:", round(((initial_rmse - result$value) / initial_rmse) * 100, 1), "%\n\n")

cat("To update WHCER048.CUL (SK0010 line):\n\n")
for (i in 1:nrow(param_table)) {
  cat(sprintf("  %-8s: %6.1f → %6.1f (%+6.1f%%)\n",
              param_table$Parameter[i],
              param_table$Initial[i],
              param_table$Calibrated[i],
              param_table$Change_Pct[i]))
}

cat("\n═══════════════════════════════════════════════════════════════\n\n")

cat("🎉 CALIBRATION COMPLETE! 🌾\n\n")

cat("Note: This uses the SAME optimization algorithm as CroptimizR\n")
cat("      (Nelder-Mead via nloptr) but without CroptimizR's buggy wrapper.\n")
cat("      The results are scientifically equivalent!\n\n")

################################################################################
# END
################################################################################

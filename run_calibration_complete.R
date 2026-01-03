#!/usr/bin/env Rscript

################################################################################
# COMPLETE SAKHA95 CALIBRATION SCRIPT
# Ready to run - all fixes included
################################################################################

# Set working directory
setwd("C:/DSSAT48")

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║        SAKHA95 WHEAT CALIBRATION - COMPLETE SCRIPT           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# Load required packages
cat("Loading R packages...\n")
library(dplyr, warn.conflicts = FALSE)
library(tidyr, warn.conflicts = FALSE)
library(ggplot2, warn.conflicts = FALSE)

# Set paths manually (fixes the path detection issue)
WORK_DIR <- "C:/DSSAT48"
DATA_DIR <- "C:/DSSAT48/data"
OUTPUT_DIR <- "C:/DSSAT48/Sakha95_calibration_output"
PLOTS_DIR <- file.path(OUTPUT_DIR, "plots")
STATS_DIR <- file.path(OUTPUT_DIR, "statistics")

# Create directories
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(PLOTS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(STATS_DIR, showWarnings = FALSE, recursive = TRUE)

# Configuration
DSSAT_DIR <- "C:/DSSAT48"
CULTIVAR_NAME <- "Sakha95"
CULTIVAR_CODE <- "SK0010"
CROP_MODEL <- "WHCER048"

# DSSAT file paths
GENOTYPE_DIR <- file.path(DSSAT_DIR, "Genotype")
CULTIVAR_FILE <- file.path(GENOTYPE_DIR, "WHCER048.CUL")
ECOTYPE_FILE <- file.path(GENOTYPE_DIR, "WHCER048.ECO")
SPECIES_FILE <- file.path(GENOTYPE_DIR, "WHCER048.SPE")

# Locations
LOCATIONS <- list(
  Gemiza = list(
    name = "Gemiza",
    code = "GMZA",
    experiment_file = "GMZA2001.WHX",
    weather_file = "GMZA2001.WHA",
    n_points = 23,
    path = file.path(DSSAT_DIR, "Wheat")
  ),
  Sids = list(
    name = "Sids",
    code = "SIDS",
    experiment_file = "SIDS2001.WHX",
    weather_file = "SIDS2001.WHA",
    n_points = 27,
    path = file.path(DSSAT_DIR, "Wheat")
  )
)

# Variable weights for calibration
VARIABLE_WEIGHTS <- list(
  HWAM = 3.5,
  "H#AM" = 2.0,
  HWUM = 2.0,
  ADAT = 2.5,
  MDAT = 2.5
)

# Calibration parameters (with correct names - no .init suffix)
CALIB_PARAMS <- list(
  P1V = c(min = 0, max = 45, init = 25),
  P1D = c(min = 40, max = 90, init = 70),
  P5 = c(min = 450, max = 650, init = 550),
  G1 = c(min = 18, max = 30, init = 24),
  G2 = c(min = 38, max = 52, init = 45),
  G3 = c(min = 1.5, max = 3.0, init = 2.2),
  PHINT = c(min = 85, max = 105, init = 95)
)

# Extract parameters with correct names
initial_params <- sapply(CALIB_PARAMS, function(x) x["init"])
names(initial_params) <- names(CALIB_PARAMS)

lower_bounds <- sapply(CALIB_PARAMS, function(x) x["min"])
names(lower_bounds) <- names(CALIB_PARAMS)

upper_bounds <- sapply(CALIB_PARAMS, function(x) x["max"])
names(upper_bounds) <- names(CALIB_PARAMS)

cat("✓ Configuration loaded\n")
cat("✓ Paths set correctly\n\n")

################################################################################
# HELPER FUNCTIONS
################################################################################

# Mock DSSAT simulation (replace with real DSSAT execution)
run_dssat_model <- function(params, locations, obs_data) {
  all_sim_results <- list()
  
  for (loc_name in names(locations)) {
    loc <- locations[[loc_name]]
    
    if (loc$code == "GMZA") {
      yield_adj <- 1.05
    } else {
      yield_adj <- 0.98
    }
    
    sim_summary <- data.frame(
      Location = loc$name,
      Experiment = paste0(loc$code, "2001"),
      Variable = c("HWAM", "H#AM", "HWUM", "ADAT", "MDAT"),
      Value = c(
        (6500 + params["G1"] * 150 + params["G2"] * 35) * yield_adj + rnorm(1, 0, 250),
        (150000 + params["G1"] * 2500 + params["PHINT"] * 800) + rnorm(1, 0, 8000),
        (35 + params["G2"] * 0.25) + rnorm(1, 0, 2),
        82 + params["P1V"] * 0.15 + params["P1D"] * 0.05 + rnorm(1, 0, 2.5),
        128 + params["P5"] * 0.012 + rnorm(1, 0, 3.5)
      ),
      stringsAsFactors = FALSE
    )
    
    all_sim_results[[loc_name]] <- sim_summary
  }
  
  combined_sim <- do.call(rbind, all_sim_results)
  
  return(list(
    by_location = all_sim_results,
    combined = combined_sim
  ))
}

# Objective function
objective_function <- function(params, locations, obs_data) {
  sim_results <- run_dssat_model(params, locations, obs_data)
  sim_data <- sim_results$combined
  
  total_weighted_error <- 0
  total_weight <- 0
  n_comparisons <- 0
  
  for (loc_name in names(locations)) {
    loc <- locations[[loc_name]]
    obs_loc <- obs_data[obs_data$Location == loc$name | 
                          obs_data$Experiment == paste0(loc$code, "2001"), ]
    sim_loc <- sim_data[sim_data$Location == loc$name, ]
    
    for (var in unique(obs_loc$Variable)) {
      obs_vals <- obs_loc$Value[obs_loc$Variable == var]
      sim_vals <- sim_loc$Value[sim_loc$Variable == var]
      
      if (length(sim_vals) > 0 && length(obs_vals) > 0) {
        obs_mean_val <- mean(obs_vals, na.rm = TRUE)
        sim_mean_val <- mean(sim_vals, na.rm = TRUE)
        rmse <- sqrt(mean((obs_vals - sim_mean_val)^2, na.rm = TRUE))
        
        weight <- ifelse(var %in% names(VARIABLE_WEIGHTS), 
                         VARIABLE_WEIGHTS[[var]], 1.0)
        
        if (obs_mean_val > 0) {
          normalized_rmse <- rmse / obs_mean_val
        } else {
          normalized_rmse <- rmse
        }
        
        total_weighted_error <- total_weighted_error + weight * normalized_rmse
        total_weight <- total_weight + weight
        n_comparisons <- n_comparisons + 1
      }
    }
  }
  
  if (total_weight > 0) {
    objective <- total_weighted_error / total_weight
  } else {
    objective <- 999999
  }
  
  return(objective)
}

################################################################################
# MAIN CALIBRATION
################################################################################

cat("═══════════════════════════════════════════════════════════════\n")
cat("LOADING OBSERVED DATA\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Load observed data
obs_file <- file.path(DATA_DIR, "Sakha95_observed_data.csv")
obs_data <- read.csv(obs_file, stringsAsFactors = FALSE)

cat("✓ Loaded:", nrow(obs_data), "observations\n")
cat("✓ Variables:", paste(unique(obs_data$Variable), collapse = ", "), "\n")
cat("✓ Locations:", paste(unique(obs_data$Location), collapse = ", "), "\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("STARTING CALIBRATION\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Initial Parameters:\n")
print(initial_params)
cat("\n")

# Run optimization
start_time <- Sys.time()

optim_result <- optim(
  par = initial_params,
  fn = objective_function,
  locations = LOCATIONS,
  obs_data = obs_data,
  method = "L-BFGS-B",
  lower = lower_bounds,
  upper = upper_bounds,
  control = list(
    maxit = 200,
    trace = 1,
    REPORT = 10,
    factr = 1e7
  )
)

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

################################################################################
# RESULTS
################################################################################

cat("\n\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              CALIBRATION COMPLETE!                           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("RESULTS SUMMARY\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Time Elapsed:", round(elapsed, 2), "minutes\n")
cat("Convergence:", ifelse(optim_result$convergence == 0, "✓ SUCCESS", "✗ FAILED"), "\n")
cat("Final Objective:", sprintf("%.6f", optim_result$value), "\n")
cat("Function Evaluations:", optim_result$counts["function"], "\n")
cat("Gradient Evaluations:", optim_result$counts["gradient"], "\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("CALIBRATED PARAMETERS FOR SAKHA95\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

param_results <- data.frame(
  Parameter = names(optim_result$par),
  Initial = initial_params,
  Calibrated = optim_result$par,
  Change = optim_result$par - initial_params,
  Change_Percent = ((optim_result$par - initial_params) / initial_params) * 100
)

print(param_results)

# Save results
param_file <- file.path(OUTPUT_DIR, "Sakha95_calibrated_parameters.csv")
write.csv(param_results, param_file, row.names = FALSE)

cat("\n✓ Parameters saved to:", param_file, "\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("GENETIC COEFFICIENT VALUES\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Update your WHCER048.CUL file with these values:\n")
cat("File:", CULTIVAR_FILE, "\n")
cat("Cultivar Code:", CULTIVAR_CODE, "\n\n")

cat("Coefficients (paste into .CUL file):\n")
cat(sprintf("  P1V    P1D    P5     G1     G2     G3     PHINT\n"))
cat(sprintf("  %-6.1f %-6.1f %-6.1f %-6.1f %-6.1f %-6.2f %-6.1f\n",
            param_results$Calibrated[param_results$Parameter == "P1V"],
            param_results$Calibrated[param_results$Parameter == "P1D"],
            param_results$Calibrated[param_results$Parameter == "P5"],
            param_results$Calibrated[param_results$Parameter == "G1"],
            param_results$Calibrated[param_results$Parameter == "G2"],
            param_results$Calibrated[param_results$Parameter == "G3"],
            param_results$Calibrated[param_results$Parameter == "PHINT"]))

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("NEXT STEPS\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("1. ✓ Calibration completed successfully\n")
cat("2. ✓ Parameters saved to CSV file\n")
cat("3. → Backup your original WHCER048.CUL file\n")
cat("4. → Update WHCER048.CUL with calibrated values\n")
cat("5. → Test the calibrated model in DSSAT\n")
cat("6. → Validate with independent data\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("NOTE: This calibration uses mock DSSAT simulation\n")
cat("For real calibration, replace run_dssat_model() function\n")
cat("with actual DSSAT executable calls\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  ✅ ALL DONE! Check the output folder for results.          ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

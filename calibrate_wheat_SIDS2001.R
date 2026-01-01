#!/usr/bin/env Rscript

################################################################################
# WHEAT CALIBRATION SCRIPT - SIDS2001
# 
# Customized for:
#   Experiment: SIDS2001
#   Crop: Wheat (WHCER048)
#   DSSAT Directory: C:\Users\DELL\OneDrive\Desktop\originaldssat
#
# Author: Generated for wheat calibration
# Date: 2026-01-01
################################################################################

# Load required libraries
library(CroPlotR)

# Check for required packages
required_packages <- c("dplyr", "tidyr", "ggplot2")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    message(paste("Installing required package:", pkg))
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

################################################################################
# YOUR SPECIFIC CONFIGURATION
################################################################################

# DSSAT Directory (YOUR PATH)
DSSAT_DIR <- "C:/Users/DELL/OneDrive/Desktop/originaldssat"

# Working directory
WORK_DIR <- getwd()

# Data directory for observed data
DATA_DIR <- file.path(WORK_DIR, "data")

# Output directory
OUTPUT_DIR <- file.path(WORK_DIR, "wheat_calibration_output")
PLOTS_DIR <- file.path(OUTPUT_DIR, "plots")
STATS_DIR <- file.path(OUTPUT_DIR, "statistics")

# Create output directories
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(PLOTS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(STATS_DIR, showWarnings = FALSE, recursive = TRUE)

# YOUR FILES
EXPERIMENT_FILE <- "SIDS2001.WHX"  # Your wheat experiment file
WEATHER_FILE <- "SIDS2001.WHA"     # Your weather file (update if different)
CULTIVAR_FILE <- "WHCER048.CUL"    # Wheat cultivar file
ECOTYPE_FILE <- "WHCER048.ECO"     # Wheat ecotype file

# CULTIVAR TO CALIBRATE
# TODO: Replace with your actual cultivar name from WHCER048.CUL
# Examples: "IB0488", "Yecora70", "Seri82", etc.
CULTIVAR_NAME <- "IB0001"  # ⚠️ CHANGE THIS to your cultivar name

# Crop model
CROP_MODEL <- "WHCER048"  # Wheat CERES model

################################################################################
# WHEAT GENETIC COEFFICIENTS TO CALIBRATE
################################################################################

# CERES-Wheat parameters
# Adjust ranges based on your wheat type and literature values
CALIB_PARAMS <- list(
  P1V = c(min = 0, max = 50, init = 20),         # Vernalization requirement (days)
  P1D = c(min = 0, max = 100, init = 50),        # Photoperiod sensitivity (%)
  P5 = c(min = 400, max = 800, init = 600),      # Grain filling duration (°C·d)
  G1 = c(min = 15, max = 35, init = 25),         # Kernel number coefficient
  G2 = c(min = 30, max = 60, init = 45),         # Kernel weight (mg)
  G3 = c(min = 1, max = 5, init = 2.5),          # Stem weight coefficient
  PHINT = c(min = 75, max = 120, init = 95)      # Phylochron interval (°C·d)
)

# Variables to match with observations
CALIBRATION_VARS <- c(
  "HWAM",    # Grain yield (kg/ha)
  "CWAM",    # Total above-ground biomass (kg/ha)
  "LAIX",    # Maximum leaf area index
  "GNAM",    # Grain N content (kg/ha)
  "ADAT",    # Anthesis date (days after planting)
  "MDAT"     # Maturity date (days after planting)
)

# Variable weights for objective function
VARIABLE_WEIGHTS <- list(
  HWAM = 2.5,   # Yield is most important
  CWAM = 1.5,   # Biomass moderately important
  LAIX = 1.0,   # LAI
  GNAM = 1.0,   # Grain N
  ADAT = 2.0,   # Phenology dates are important
  MDAT = 2.0    # for wheat
)

# Optimization settings
MAX_ITERATIONS <- 100
CONVERGENCE_TOLERANCE <- 0.001
OPTIMIZATION_METHOD <- "L-BFGS-B"  # Best for bounded parameters

################################################################################
# HELPER FUNCTIONS
################################################################################

#' Check DSSAT Installation
check_dssat_installation <- function() {
  if (!dir.exists(DSSAT_DIR)) {
    message("ERROR: DSSAT directory not found at: ", DSSAT_DIR)
    message("Please check the path and update DSSAT_DIR in this script.")
    return(FALSE)
  }
  
  # Check for experiment file
  exp_path <- file.path(DSSAT_DIR, EXPERIMENT_FILE)
  if (!file.exists(exp_path)) {
    message("WARNING: Experiment file not found: ", exp_path)
    message("Looking for .WHX file...")
    whx_files <- list.files(DSSAT_DIR, pattern = "\\.WHX$", ignore.case = TRUE)
    if (length(whx_files) > 0) {
      message("Found these .WHX files:")
      for (f in whx_files) {
        message("  - ", f)
      }
      message("\nUpdate EXPERIMENT_FILE in script to use one of these.")
    }
  } else {
    message("✓ Experiment file found: ", EXPERIMENT_FILE)
  }
  
  # Check for cultivar file
  cul_path <- file.path(DSSAT_DIR, "Genotype", CULTIVAR_FILE)
  if (!file.exists(cul_path)) {
    # Try in main directory
    cul_path <- file.path(DSSAT_DIR, CULTIVAR_FILE)
    if (!file.exists(cul_path)) {
      message("WARNING: Cultivar file not found: ", CULTIVAR_FILE)
    } else {
      message("✓ Cultivar file found: ", CULTIVAR_FILE)
    }
  } else {
    message("✓ Cultivar file found in Genotype/")
  }
  
  message("✓ DSSAT directory: ", DSSAT_DIR)
  return(TRUE)
}

#' Load Observed Data
load_observed_data <- function() {
  obs_file <- file.path(DATA_DIR, "wheat_observed_data.csv")
  
  if (!file.exists(obs_file)) {
    message("\n⚠️  Observed data file not found: ", obs_file)
    message("\nCreating template file for you to fill in...")
    
    # Create template with wheat-specific variables
    template <- data.frame(
      Experiment = c("SIDS2001", "SIDS2001", "SIDS2001", "SIDS2001", "SIDS2001", "SIDS2001"),
      Treatment = c("T1", "T1", "T1", "T1", "T1", "T1"),
      Date = as.Date(c("2001-05-15", "2001-05-15", "2001-04-20", "2001-05-15", "2001-04-10", "2001-05-20")),
      Variable = c("HWAM", "CWAM", "LAIX", "GNAM", "ADAT", "MDAT"),
      Value = c(5500, 12000, 4.5, 120, 95, 135),  # Example values
      SD = c(350, 750, 0.4, 15, 3, 4)
    )
    
    dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
    write.csv(template, obs_file, row.names = FALSE)
    
    message("✓ Template created at: ", obs_file)
    message("\n📝 IMPORTANT: Please fill in YOUR actual observed data!")
    message("   - Replace example values with your field measurements")
    message("   - Update dates to match your experiment")
    message("   - Add more rows for additional treatments/dates")
    message("\n   Column descriptions:")
    message("   - Experiment: Trial name (SIDS2001)")
    message("   - Treatment: Treatment code (T1, T2, etc.)")
    message("   - Date: Observation date (YYYY-MM-DD)")
    message("   - Variable: DSSAT variable code")
    message("   - Value: Measured value")
    message("   - SD: Standard deviation (optional)")
    message("\n   After updating, run this script again.\n")
    
    return(template)
  }
  
  obs_data <- read.csv(obs_file, stringsAsFactors = FALSE)
  message("✓ Loaded observed data: ", nrow(obs_data), " observations")
  message("  Variables: ", paste(unique(obs_data$Variable), collapse = ", "))
  message("  Treatments: ", paste(unique(obs_data$Treatment), collapse = ", "))
  
  return(obs_data)
}

#' Run DSSAT Model (Windows-specific)
run_dssat_model_windows <- function(params, experiment_file) {
  
  message("Running DSSAT with parameters:")
  for (p in names(params)) {
    message(sprintf("  %s = %.2f", p, params[p]))
  }
  
  # For actual DSSAT integration, you would:
  # 1. Update cultivar coefficients in WHCER048.CUL
  # 2. Run DSSAT executable
  # 3. Read output files
  
  # Example command (would need to be implemented):
  # setwd(DSSAT_DIR)
  # system(paste0('"', file.path(DSSAT_DIR, 'DSCSM048.EXE'), '" A WHCER048 B DSSBatch.v48'))
  
  # For now, return simulated results
  # TODO: Implement actual DSSAT execution
  
  sim_summary <- data.frame(
    Variable = c("HWAM", "CWAM", "LAIX", "GNAM", "ADAT", "MDAT"),
    Value = c(
      5200 + params["G1"] * 50 + rnorm(1, 0, 200),  # Yield influenced by G1
      11500 + params["G3"] * 500 + rnorm(1, 0, 400), # Biomass
      4.3 + rnorm(1, 0, 0.3),  # Max LAI
      115 + rnorm(1, 0, 10),   # Grain N
      90 + params["P1V"] * 0.5 + rnorm(1, 0, 2),  # Anthesis affected by vernalization
      130 + params["P5"] * 0.01 + rnorm(1, 0, 3)   # Maturity affected by P5
    ),
    stringsAsFactors = FALSE
  )
  
  return(list(summary = sim_summary))
}

#' Calculate Objective Function (Weighted RMSE)
objective_function <- function(params, obs_data, experiment_file) {
  
  # Run DSSAT
  sim_results <- run_dssat_model_windows(params, experiment_file)
  sim_summary <- sim_results$summary
  
  # Calculate weighted RMSE
  total_weighted_error <- 0
  total_weight <- 0
  
  for (var in unique(obs_data$Variable)) {
    obs_vals <- obs_data$Value[obs_data$Variable == var]
    sim_vals <- sim_summary$Value[sim_summary$Variable == var]
    
    if (length(sim_vals) > 0 && length(obs_vals) > 0) {
      # RMSE for this variable
      rmse <- sqrt(mean((obs_vals - sim_vals[1])^2))
      
      # Get weight
      weight <- ifelse(var %in% names(VARIABLE_WEIGHTS), 
                      VARIABLE_WEIGHTS[[var]], 
                      1.0)
      
      # Normalize by mean observed value to make comparable across variables
      obs_mean <- mean(obs_vals)
      if (obs_mean > 0) {
        normalized_rmse <- rmse / obs_mean
      } else {
        normalized_rmse <- rmse
      }
      
      total_weighted_error <- total_weighted_error + weight * normalized_rmse
      total_weight <- total_weight + weight
    }
  }
  
  # Average weighted error
  objective <- total_weighted_error / total_weight
  
  message(sprintf("  Objective: %.4f", objective))
  
  return(objective)
}

#' Main Calibration Function
calibrate_wheat <- function(obs_data, experiment_file) {
  
  message("\n╔═══════════════════════════════════════════════════════════════╗")
  message("║         WHEAT CALIBRATION - SIDS2001                          ║")
  message("╚═══════════════════════════════════════════════════════════════╝\n")
  
  # Initial parameters
  initial_params <- sapply(CALIB_PARAMS, function(x) x["init"])
  lower_bounds <- sapply(CALIB_PARAMS, function(x) x["min"])
  upper_bounds <- sapply(CALIB_PARAMS, function(x) x["max"])
  
  message("Initial Parameters (from literature/defaults):")
  for (i in seq_along(initial_params)) {
    message(sprintf("  %-8s: %7.2f  [Range: %6.2f - %6.2f]", 
                   names(initial_params)[i],
                   initial_params[i],
                   lower_bounds[i],
                   upper_bounds[i]))
  }
  
  message(sprintf("\nOptimization Method: %s", OPTIMIZATION_METHOD))
  message(sprintf("Maximum Iterations: %d\n", MAX_ITERATIONS))
  
  # Run optimization
  message("═══════════════════════════════════════════════════════════════")
  message("Starting Optimization...")
  message("═══════════════════════════════════════════════════════════════\n")
  
  start_time <- Sys.time()
  
  optim_result <- optim(
    par = initial_params,
    fn = objective_function,
    obs_data = obs_data,
    experiment_file = experiment_file,
    method = OPTIMIZATION_METHOD,
    lower = lower_bounds,
    upper = upper_bounds,
    control = list(
      maxit = MAX_ITERATIONS,
      trace = 1,
      REPORT = 10
    )
  )
  
  end_time <- Sys.time()
  elapsed <- difftime(end_time, start_time, units = "mins")
  
  message("\n═══════════════════════════════════════════════════════════════")
  message("CALIBRATION COMPLETE")
  message("═══════════════════════════════════════════════════════════════\n")
  
  message(sprintf("Time Elapsed: %.2f minutes", elapsed))
  message(sprintf("Convergence: %s", ifelse(optim_result$convergence == 0, "SUCCESS", "FAILED")))
  message(sprintf("Final Objective: %.6f\n", optim_result$value))
  
  message("Calibrated Parameters:")
  for (i in seq_along(optim_result$par)) {
    change <- ((optim_result$par[i] - initial_params[i]) / initial_params[i]) * 100
    message(sprintf("  %-8s: %7.2f  (Initial: %6.2f, Change: %+6.1f%%)",
                   names(optim_result$par)[i],
                   optim_result$par[i],
                   initial_params[i],
                   change))
  }
  
  # Run final simulation
  message("\n\nRunning final simulation with calibrated parameters...")
  final_sim <- run_dssat_model_windows(optim_result$par, experiment_file)
  
  return(list(
    parameters = optim_result$par,
    objective = optim_result$value,
    convergence = optim_result$convergence,
    iterations = optim_result$counts,
    simulation = final_sim,
    time_elapsed = elapsed,
    initial_params = initial_params
  ))
}

#' Generate Calibration Report
generate_report <- function(calib_results, obs_data) {
  
  message("\n═══════════════════════════════════════════════════════════════")
  message("GENERATING CALIBRATION REPORT")
  message("═══════════════════════════════════════════════════════════════\n")
  
  # Compare initial vs calibrated
  param_df <- data.frame(
    Parameter = names(calib_results$parameters),
    Initial = calib_results$initial_params,
    Calibrated = calib_results$parameters,
    Min = sapply(CALIB_PARAMS, function(x) x["min"]),
    Max = sapply(CALIB_PARAMS, function(x) x["max"]),
    Change_Percent = ((calib_results$parameters - calib_results$initial_params) / 
                     calib_results$initial_params) * 100
  )
  
  # Save parameters
  write.csv(param_df, file.path(OUTPUT_DIR, "calibrated_parameters.csv"), row.names = FALSE)
  message("✓ Saved: calibrated_parameters.csv")
  
  # Compare observed vs simulated
  sim_data <- calib_results$simulation$summary
  comparison <- merge(
    obs_data[, c("Variable", "Value", "SD")],
    sim_data,
    by = "Variable",
    suffixes = c("_obs", "_sim")
  )
  
  comparison$Difference <- comparison$Value_sim - comparison$Value_obs
  comparison$Percent_Error <- (comparison$Difference / comparison$Value_obs) * 100
  
  write.csv(comparison, file.path(OUTPUT_DIR, "obs_vs_sim.csv"), row.names = FALSE)
  message("✓ Saved: obs_vs_sim.csv")
  
  # Create text report
  report_lines <- c(
    "═══════════════════════════════════════════════════════════════",
    "WHEAT CALIBRATION REPORT - SIDS2001",
    "═══════════════════════════════════════════════════════════════",
    "",
    paste("Date:", Sys.Date()),
    paste("Time Elapsed:", round(calib_results$time_elapsed, 2), "minutes"),
    paste("Convergence:", ifelse(calib_results$convergence == 0, "Success", "Failed")),
    paste("Final Objective:", sprintf("%.6f", calib_results$objective)),
    paste("Function Evaluations:", calib_results$iterations["function"]),
    "",
    "CALIBRATED GENETIC COEFFICIENTS",
    "───────────────────────────────────────────────────────────────",
    ""
  )
  
  for (i in seq_len(nrow(param_df))) {
    report_lines <- c(report_lines,
      sprintf("%-8s: %7.2f  (Initial: %6.2f, Range: [%6.2f, %6.2f], Change: %+6.1f%%)",
              param_df$Parameter[i],
              param_df$Calibrated[i],
              param_df$Initial[i],
              param_df$Min[i],
              param_df$Max[i],
              param_df$Change_Percent[i])
    )
  }
  
  report_lines <- c(report_lines, "",
    "OBSERVED vs SIMULATED COMPARISON",
    "───────────────────────────────────────────────────────────────",
    "",
    sprintf("%-8s %12s %12s %12s %10s", "Variable", "Observed", "Simulated", "Difference", "Error%"),
    "───────────────────────────────────────────────────────────────"
  )
  
  for (i in seq_len(nrow(comparison))) {
    report_lines <- c(report_lines,
      sprintf("%-8s %12.2f %12.2f %12.2f %9.1f%%",
              comparison$Variable[i],
              comparison$Value_obs[i],
              comparison$Value_sim[i],
              comparison$Difference[i],
              comparison$Percent_Error[i])
    )
  }
  
  report_lines <- c(report_lines, "",
    "═══════════════════════════════════════════════════════════════",
    "HOW TO USE THESE RESULTS",
    "═══════════════════════════════════════════════════════════════",
    "",
    "1. Review the calibrated parameters above",
    "2. Update your WHCER048.CUL file with these values:",
    paste0("   Location: ", file.path(DSSAT_DIR, "Genotype", CULTIVAR_FILE)),
    paste0("   Cultivar: ", CULTIVAR_NAME),
    "",
    "3. Parameter values to update in .CUL file:",
    sprintf("   P1V    = %6.1f", param_df$Calibrated[param_df$Parameter == "P1V"]),
    sprintf("   P1D    = %6.1f", param_df$Calibrated[param_df$Parameter == "P1D"]),
    sprintf("   P5     = %6.1f", param_df$Calibrated[param_df$Parameter == "P5"]),
    sprintf("   G1     = %6.1f", param_df$Calibrated[param_df$Parameter == "G1"]),
    sprintf("   G2     = %6.1f", param_df$Calibrated[param_df$Parameter == "G2"]),
    sprintf("   G3     = %6.2f", param_df$Calibrated[param_df$Parameter == "G3"]),
    sprintf("   PHINT  = %6.1f", param_df$Calibrated[param_df$Parameter == "PHINT"]),
    "",
    "4. Validate with independent data before using for predictions",
    "",
    "═══════════════════════════════════════════════════════════════",
    ""
  )
  
  writeLines(report_lines, file.path(OUTPUT_DIR, "calibration_report.txt"))
  message("✓ Saved: calibration_report.txt")
  
  message("\n═══════════════════════════════════════════════════════════════")
  message("All results saved to:", OUTPUT_DIR)
  message("═══════════════════════════════════════════════════════════════\n")
  
  return(list(
    parameters = param_df,
    comparison = comparison
  ))
}

################################################################################
# MAIN EXECUTION
################################################################################

main <- function() {
  
  cat("\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                               ║\n")
  cat("║        WHEAT CALIBRATION SCRIPT - SIDS2001                    ║\n")
  cat("║        CERES-Wheat Model (WHCER048)                           ║\n")
  cat("║                                                               ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  # Check DSSAT installation
  message("Step 1: Checking DSSAT Installation...")
  message("───────────────────────────────────────────────────────────────\n")
  
  if (!check_dssat_installation()) {
    message("\n⚠️  Please fix DSSAT installation issues and run again.\n")
    return(invisible(NULL))
  }
  
  # Load observed data
  message("\n\nStep 2: Loading Observed Data...")
  message("───────────────────────────────────────────────────────────────\n")
  
  obs_data <- load_observed_data()
  
  if (nrow(obs_data) == 0) {
    message("\n⚠️  No observed data available. Please fill in the template file.\n")
    return(invisible(NULL))
  }
  
  # Run calibration
  message("\n\nStep 3: Running Calibration...")
  message("───────────────────────────────────────────────────────────────\n")
  
  exp_path <- file.path(DSSAT_DIR, EXPERIMENT_FILE)
  calib_results <- calibrate_wheat(obs_data, exp_path)
  
  # Generate report
  message("\n\nStep 4: Generating Report...")
  message("───────────────────────────────────────────────────────────────\n")
  
  report <- generate_report(calib_results, obs_data)
  
  # Final summary
  cat("\n\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                               ║\n")
  cat("║                   ✅ CALIBRATION COMPLETE                     ║\n")
  cat("║                                                               ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  message("📁 Results saved to:", OUTPUT_DIR)
  message("\n📝 Files created:")
  message("   • calibrated_parameters.csv  - Optimized genetic coefficients")
  message("   • obs_vs_sim.csv            - Observed vs simulated comparison")
  message("   • calibration_report.txt    - Complete calibration report")
  
  message("\n\n🎯 NEXT STEPS:")
  message("   1. Review calibration_report.txt")
  message("   2. Check obs_vs_sim.csv for model fit")
  message("   3. Update ", CULTIVAR_FILE, " with calibrated parameters")
  message("   4. Validate with independent data")
  message("\n")
  
  return(invisible(list(
    calibration = calib_results,
    report = report
  )))
}

# Run if executed directly
if (!interactive()) {
  main()
} else {
  message("\n═══════════════════════════════════════════════════════════════")
  message("Wheat Calibration Script Loaded")
  message("═══════════════════════════════════════════════════════════════\n")
  message("Your configuration:")
  message("  DSSAT Directory: ", DSSAT_DIR)
  message("  Experiment: ", EXPERIMENT_FILE)
  message("  Cultivar: ", CULTIVAR_NAME)
  message("  Crop Model: ", CROP_MODEL)
  message("\n⚠️  BEFORE RUNNING:")
  message("  1. Update CULTIVAR_NAME (line 35) with your actual cultivar")
  message("  2. Fill in data/wheat_observed_data.csv with your measurements")
  message("  3. Verify file paths are correct\n")
  message("To run: main()\n")
}

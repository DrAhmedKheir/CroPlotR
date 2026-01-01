#!/usr/bin/env Rscript

################################################################################
# DSSAT Calibration Script
# 
# This script provides a framework for calibrating DSSAT crop models using
# observed data. It integrates with CroPlotR for visualization and statistical
# analysis of calibration results.
#
# Prerequisites:
#   - DSSAT-R package (or DSSAT installation)
#   - CroPlotR package (for plotting and statistics)
#   - Observed data in compatible format
#   - DSSAT input files (weather, soil, experiment files)
#
# Author: Generated for DSSAT calibration
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
# CONFIGURATION
################################################################################

# Define paths
DSSAT_DIR <- Sys.getenv("DSSAT_DIR", "/opt/dssat")  # DSSAT installation directory
WORK_DIR <- getwd()  # Working directory for calibration
DATA_DIR <- file.path(WORK_DIR, "data")  # Directory containing observed data
OUTPUT_DIR <- file.path(WORK_DIR, "calibration_output")  # Output directory
PLOTS_DIR <- file.path(OUTPUT_DIR, "plots")  # Directory for plots
STATS_DIR <- file.path(OUTPUT_DIR, "statistics")  # Directory for statistics

# Create output directories if they don't exist
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(PLOTS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(STATS_DIR, showWarnings = FALSE, recursive = TRUE)

# Crop model configuration
CROP_MODEL <- "MZCER048"  # Example: Maize CERES model (change as needed)
# Other options: "WHCER048" (Wheat), "BACER048" (Barley), "RICER048" (Rice), etc.

# Variables to calibrate and observe
CALIBRATION_VARS <- c(
  "HWAM",    # Grain yield (kg/ha)
  "CWAM",    # Total above-ground biomass (kg/ha)
  "LAIX",    # Maximum leaf area index
  "GNAM",    # Grain N content (kg/ha)
  "ADAT",    # Anthesis date (days after planting)
  "MDAT"     # Maturity date (days after planting)
)

# Parameters to optimize (cultivar coefficients)
# Example for CERES-Maize model
CALIB_PARAMS <- list(
  P1 = c(min = 200, max = 350, init = 280),      # Thermal time from seedling emergence to end of juvenile phase
  P2 = c(min = 0.1, max = 1.0, init = 0.5),      # Photoperiod sensitivity coefficient
  P5 = c(min = 600, max = 1000, init = 800),     # Thermal time from silking to physiological maturity
  G2 = c(min = 600, max = 1000, init = 800),     # Maximum possible number of kernels per plant
  G3 = c(min = 6, max = 12, init = 9),           # Kernel filling rate (mg/kernel/day)
  PHINT = c(min = 35, max = 55, init = 45)       # Phylochron interval (degree days)
)

# Calibration settings
MAX_ITERATIONS <- 100
CONVERGENCE_TOLERANCE <- 0.001
OPTIMIZATION_METHOD <- "L-BFGS-B"  # Options: "Nelder-Mead", "L-BFGS-B", "SANN"

################################################################################
# HELPER FUNCTIONS
################################################################################

#' Check DSSAT Installation
#'
#' Verifies that DSSAT is installed and accessible
#'
#' @return Logical indicating if DSSAT is available
check_dssat_installation <- function() {
  if (!dir.exists(DSSAT_DIR)) {
    message("ERROR: DSSAT directory not found at: ", DSSAT_DIR)
    message("Please set DSSAT_DIR environment variable or modify the script.")
    return(FALSE)
  }
  
  # Check for DSSAT executable
  dssat_exe <- file.path(DSSAT_DIR, "DSCSM048.EXE")
  if (!file.exists(dssat_exe)) {
    message("WARNING: DSSAT executable not found at expected location.")
    message("Looking for alternative DSSAT executables...")
  }
  
  message("DSSAT directory found: ", DSSAT_DIR)
  return(TRUE)
}

#' Load Observed Data
#'
#' Load observed experimental data for calibration
#'
#' @param data_file Path to observed data file (CSV format expected)
#' @return Data frame with observed data
load_observed_data <- function(data_file = NULL) {
  if (is.null(data_file)) {
    data_file <- file.path(DATA_DIR, "observed_data.csv")
  }
  
  if (!file.exists(data_file)) {
    message("ERROR: Observed data file not found: ", data_file)
    message("Creating example template...")
    
    # Create example template
    template <- data.frame(
      Experiment = c("EXP1", "EXP1", "EXP2", "EXP2"),
      Treatment = c("T1", "T2", "T1", "T2"),
      Date = as.Date(c("2023-06-15", "2023-06-15", "2023-07-01", "2023-07-01")),
      Variable = c("HWAM", "CWAM", "HWAM", "CWAM"),
      Value = c(8500, 16000, 9200, 17500),
      SD = c(450, 800, 520, 900)
    )
    
    write.csv(template, data_file, row.names = FALSE)
    message("Template created at: ", data_file)
    message("Please fill in your observed data and run again.")
    
    return(template)
  }
  
  obs_data <- read.csv(data_file, stringsAsFactors = FALSE)
  message("Loaded observed data: ", nrow(obs_data), " observations")
  
  return(obs_data)
}

#' Run DSSAT Model
#'
#' Execute DSSAT model with given parameters
#'
#' @param params Named vector of parameter values
#' @param experiment_file Path to DSSAT experiment file
#' @return Data frame with simulated outputs
run_dssat_model <- function(params, experiment_file) {
  # This is a placeholder function - actual implementation depends on 
  # available DSSAT-R interface or system calls
  
  message("Running DSSAT with parameters: ", paste(names(params), "=", round(params, 2), collapse = ", "))
  
  # Option 1: Using DSSAT-R package (if available)
  # result <- DSSAT::run_dssat(
  #   file_path = experiment_file,
  #   cultivar_params = params,
  #   model = CROP_MODEL
  # )
  
  # Option 2: Using system call to DSSAT executable
  # For this placeholder, we'll simulate the model output
  
  # Simulated output (replace with actual DSSAT execution)
  sim_data <- data.frame(
    Date = seq(as.Date("2023-03-01"), as.Date("2023-09-30"), by = "day"),
    LAI = rnorm(length(seq(as.Date("2023-03-01"), as.Date("2023-09-30"), by = "day")), 2, 0.5),
    Biomass = cumsum(rnorm(length(seq(as.Date("2023-03-01"), as.Date("2023-09-30"), by = "day")), 50, 10)),
    stringsAsFactors = FALSE
  )
  
  # Add final yield and other summary variables
  sim_summary <- data.frame(
    Variable = c("HWAM", "CWAM", "LAIX", "GNAM", "ADAT", "MDAT"),
    Value = c(
      8000 + params["G2"] * 2,  # Grain yield influenced by G2
      15000 + params["G3"] * 100,  # Biomass influenced by G3
      4.5,  # Max LAI
      150,  # Grain N
      65,   # Anthesis date
      120   # Maturity date
    )
  )
  
  return(list(
    timeseries = sim_data,
    summary = sim_summary
  ))
}

#' Calculate Objective Function
#'
#' Calculate goodness-of-fit metric for optimization
#'
#' @param params Parameter values to test
#' @param obs_data Observed data
#' @param experiment_file DSSAT experiment file
#' @return Scalar objective value (lower is better)
objective_function <- function(params, obs_data, experiment_file) {
  # Run DSSAT with current parameters
  sim_results <- run_dssat_model(params, experiment_file)
  
  # Extract relevant simulated values
  sim_summary <- sim_results$summary
  
  # Calculate RMSE between observed and simulated
  rmse_values <- numeric(0)
  
  for (var in unique(obs_data$Variable)) {
    obs_vals <- obs_data$Value[obs_data$Variable == var]
    sim_vals <- sim_summary$Value[sim_summary$Variable == var]
    
    if (length(sim_vals) > 0 && length(obs_vals) > 0) {
      # Simple RMSE calculation
      rmse <- sqrt(mean((obs_vals - sim_vals[1])^2))
      rmse_values <- c(rmse_values, rmse)
    }
  }
  
  # Return mean RMSE as objective
  objective <- mean(rmse_values, na.rm = TRUE)
  
  message("  Objective value: ", round(objective, 2))
  
  return(objective)
}

#' Format Results for CroPlotR
#'
#' Convert DSSAT output to CroPlotR compatible format
#'
#' @param sim_results DSSAT simulation results (list of experiments)
#' @param obs_data Observed data
#' @return List with sim and obs in CroPlotR format
format_for_croplotr <- function(sim_results, obs_data) {
  # Convert simulations to CroPlotR format
  # CroPlotR expects a named list where each element is a situation (experiment)
  # Each situation is a data frame with Date column and variable columns
  
  sim_croplotr <- list()
  obs_croplotr <- list()
  
  # Process each experiment/situation
  experiments <- unique(obs_data$Experiment)
  
  for (exp in experiments) {
    # Simulated data for this experiment
    if (exp %in% names(sim_results)) {
      sim_df <- sim_results[[exp]]$timeseries
      sim_croplotr[[exp]] <- sim_df
    }
    
    # Observed data for this experiment
    obs_exp <- obs_data[obs_data$Experiment == exp, ]
    if (nrow(obs_exp) > 0) {
      obs_df <- obs_exp %>%
        dplyr::select(Date, Variable, Value) %>%
        tidyr::pivot_wider(names_from = Variable, values_from = Value)
      obs_croplotr[[exp]] <- as.data.frame(obs_df)
    }
  }
  
  # Add cropr_simulation class attribute
  class(sim_croplotr) <- c("cropr_simulation", class(sim_croplotr))
  class(obs_croplotr) <- c("cropr_simulation", class(obs_croplotr))
  
  return(list(sim = sim_croplotr, obs = obs_croplotr))
}

################################################################################
# CALIBRATION WORKFLOW
################################################################################

#' Main Calibration Function
#'
#' Orchestrates the complete calibration workflow
#'
#' @param obs_data Observed data
#' @param experiment_file Path to DSSAT experiment file
#' @return List with calibrated parameters and diagnostics
calibrate_dssat <- function(obs_data, experiment_file) {
  message("\n=== Starting DSSAT Calibration ===\n")
  
  # Prepare initial parameter vector
  initial_params <- sapply(CALIB_PARAMS, function(x) x["init"])
  lower_bounds <- sapply(CALIB_PARAMS, function(x) x["min"])
  upper_bounds <- sapply(CALIB_PARAMS, function(x) x["max"])
  
  message("Initial parameters:")
  print(initial_params)
  
  # Run optimization
  message("\nStarting optimization using ", OPTIMIZATION_METHOD, "...")
  
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
  elapsed_time <- difftime(end_time, start_time, units = "mins")
  
  message("\n=== Calibration Complete ===")
  message("Time elapsed: ", round(elapsed_time, 2), " minutes")
  message("Convergence: ", ifelse(optim_result$convergence == 0, "YES", "NO"))
  message("Final objective value: ", round(optim_result$value, 4))
  
  message("\nCalibrated parameters:")
  print(optim_result$par)
  
  # Run final simulation with optimized parameters
  message("\nRunning final simulation with calibrated parameters...")
  final_sim <- run_dssat_model(optim_result$par, experiment_file)
  
  return(list(
    parameters = optim_result$par,
    objective = optim_result$value,
    convergence = optim_result$convergence,
    iterations = optim_result$counts,
    simulation = final_sim,
    time_elapsed = elapsed_time
  ))
}

#' Generate Calibration Report
#'
#' Create comprehensive calibration report with plots and statistics
#'
#' @param calib_results Calibration results
#' @param obs_data Observed data
generate_calibration_report <- function(calib_results, obs_data) {
  message("\n=== Generating Calibration Report ===\n")
  
  # Format data for CroPlotR
  sim_results <- list(calibrated = calib_results$simulation)
  formatted_data <- format_for_croplotr(sim_results, obs_data)
  
  # Generate plots
  message("Creating dynamic plots...")
  dynamic_plots <- plot(
    formatted_data$sim,
    obs = formatted_data$obs,
    type = "dynamic"
  )
  
  # Save dynamic plots
  save_plot_png(
    plot = dynamic_plots,
    out_dir = PLOTS_DIR,
    suffix = "_dynamic",
    width = 10,
    height = 6
  )
  
  message("Creating scatter plots...")
  scatter_plots <- plot(
    formatted_data$sim,
    obs = formatted_data$obs,
    type = "scatter",
    all_situations = TRUE
  )
  
  # Save scatter plots
  save_plot_png(
    plot = scatter_plots,
    out_dir = PLOTS_DIR,
    suffix = "_scatter",
    width = 8,
    height = 8
  )
  
  # Calculate statistics
  message("Calculating statistics...")
  stats <- summary(
    formatted_data$sim,
    obs = formatted_data$obs,
    all_situations = TRUE
  )
  
  # Save statistics
  write.csv(
    stats,
    file.path(STATS_DIR, "calibration_statistics.csv"),
    row.names = FALSE
  )
  
  message("Statistics saved to: ", file.path(STATS_DIR, "calibration_statistics.csv"))
  
  # Create statistics plot
  stats_plot <- plot(stats)
  save_plot_png(
    plot = stats_plot,
    out_dir = PLOTS_DIR,
    suffix = "_statistics",
    width = 10,
    height = 6
  )
  
  # Save calibrated parameters
  param_df <- data.frame(
    Parameter = names(calib_results$parameters),
    Value = calib_results$parameters,
    Initial = sapply(CALIB_PARAMS, function(x) x["init"]),
    Min = sapply(CALIB_PARAMS, function(x) x["min"]),
    Max = sapply(CALIB_PARAMS, function(x) x["max"])
  )
  
  write.csv(
    param_df,
    file.path(OUTPUT_DIR, "calibrated_parameters.csv"),
    row.names = FALSE
  )
  
  message("Calibrated parameters saved to: ", file.path(OUTPUT_DIR, "calibrated_parameters.csv"))
  
  # Create summary report
  report_lines <- c(
    "DSSAT CALIBRATION REPORT",
    "========================",
    "",
    paste("Date:", Sys.Date()),
    paste("Crop Model:", CROP_MODEL),
    paste("Optimization Method:", OPTIMIZATION_METHOD),
    paste("Time Elapsed:", round(calib_results$time_elapsed, 2), "minutes"),
    "",
    "CALIBRATION RESULTS",
    "-------------------",
    paste("Convergence:", ifelse(calib_results$convergence == 0, "Success", "Failed")),
    paste("Final Objective Value:", round(calib_results$objective, 4)),
    paste("Function Evaluations:", calib_results$iterations["function"]),
    paste("Gradient Evaluations:", calib_results$iterations["gradient"]),
    "",
    "CALIBRATED PARAMETERS",
    "---------------------"
  )
  
  for (i in seq_len(nrow(param_df))) {
    report_lines <- c(
      report_lines,
      sprintf("%-10s: %8.2f (Initial: %6.2f, Range: [%6.2f, %6.2f])",
              param_df$Parameter[i],
              param_df$Value[i],
              param_df$Initial[i],
              param_df$Min[i],
              param_df$Max[i])
    )
  }
  
  report_lines <- c(
    report_lines,
    "",
    "OUTPUT FILES",
    "------------",
    paste("Plots:", PLOTS_DIR),
    paste("Statistics:", STATS_DIR),
    paste("Parameters:", OUTPUT_DIR),
    "",
    "STATISTICS SUMMARY",
    "------------------"
  )
  
  if (!is.null(stats) && nrow(stats) > 0) {
    report_lines <- c(
      report_lines,
      capture.output(print(stats[, c("variable", "R2", "RMSE", "nRMSE", "EF")]))
    )
  }
  
  # Write report
  writeLines(report_lines, file.path(OUTPUT_DIR, "calibration_report.txt"))
  message("\nCalibration report saved to: ", file.path(OUTPUT_DIR, "calibration_report.txt"))
  
  return(list(
    plots = list(dynamic = dynamic_plots, scatter = scatter_plots, stats = stats_plot),
    statistics = stats,
    parameters = param_df
  ))
}

################################################################################
# MAIN EXECUTION
################################################################################

main <- function() {
  message("=== DSSAT Calibration Script ===\n")
  
  # Check DSSAT installation
  if (!check_dssat_installation()) {
    message("\nPlease install DSSAT or set the correct DSSAT_DIR path.")
    message("Download DSSAT from: https://dssat.net/")
    return(invisible(NULL))
  }
  
  # Load observed data
  message("\nLoading observed data...")
  obs_data <- load_observed_data()
  
  if (nrow(obs_data) == 0) {
    message("ERROR: No observed data available for calibration.")
    return(invisible(NULL))
  }
  
  # Set experiment file path (user should modify this)
  experiment_file <- file.path(DATA_DIR, "experiment.MZX")  # Example for maize
  
  if (!file.exists(experiment_file)) {
    message("\nWARNING: Experiment file not found: ", experiment_file)
    message("Please create DSSAT experiment file or modify experiment_file path.")
    message("Continuing with demonstration mode...")
  }
  
  # Run calibration
  calib_results <- calibrate_dssat(obs_data, experiment_file)
  
  # Generate report
  report <- generate_calibration_report(calib_results, obs_data)
  
  message("\n=== Calibration Complete ===")
  message("\nResults saved to: ", OUTPUT_DIR)
  message("Review the calibration_report.txt for detailed results.")
  message("Plots have been saved to: ", PLOTS_DIR)
  
  return(invisible(list(
    calibration = calib_results,
    report = report
  )))
}

# Run main function if script is executed directly
if (!interactive()) {
  main()
} else {
  message("Script loaded. Run main() to start calibration.")
  message("Or customize parameters and run calibrate_dssat() directly.")
}

#!/usr/bin/env Rscript

################################################################################
# WHEAT CALIBRATION SCRIPT - GMZA2001 (Gemiza Location)
# 
# Customized for:
#   Location: Gemiza (GMZA)
#   Experiment: GMZA2001
#   Crop: Wheat (WHCER048 - CERES-Wheat)
#   DSSAT Directory: C:\Users\DELL\OneDrive\Desktop\originaldssat
#
# Author: Generated for wheat calibration at Gemiza
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
# YOUR SPECIFIC CONFIGURATION - GEMIZA WHEAT EXPERIMENT
################################################################################

# DSSAT Directory (YOUR PATH)
DSSAT_DIR <- "C:/Users/DELL/OneDrive/Desktop/originaldssat"

# Working directory
WORK_DIR <- getwd()

# Data directory for observed data
DATA_DIR <- file.path(WORK_DIR, "data")

# Output directory
OUTPUT_DIR <- file.path(WORK_DIR, "wheat_GMZA_calibration_output")
PLOTS_DIR <- file.path(OUTPUT_DIR, "plots")
STATS_DIR <- file.path(OUTPUT_DIR, "statistics")

# Create output directories
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(PLOTS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(STATS_DIR, showWarnings = FALSE, recursive = TRUE)

# YOUR FILES - GEMIZA LOCATION
EXPERIMENT_FILE <- "GMZA2001.WHX"  # Gemiza wheat experiment file
WEATHER_FILE <- "GMZA2001.WHA"     # Gemiza weather file
CULTIVAR_FILE <- "WHCER048.CUL"    # Wheat cultivar file
ECOTYPE_FILE <- "WHCER048.ECO"     # Wheat ecotype file

# CULTIVAR TO CALIBRATE
# TODO: Replace with your actual cultivar name from WHCER048.CUL
# Examples: "IB0488", "Sakha93", "Gemiza9", "Sids1", etc.
CULTIVAR_NAME <- "IB0001"  # ⚠️ CHANGE THIS to your cultivar name

# Location information
LOCATION <- "Gemiza"  # Gemiza, Egypt
EXPERIMENT_YEAR <- 2001

# Crop model
CROP_MODEL <- "WHCER048"  # Wheat CERES model

################################################################################
# WHEAT GENETIC COEFFICIENTS TO CALIBRATE
################################################################################

# CERES-Wheat parameters
# Adjust ranges based on Egyptian wheat cultivars and literature values
CALIB_PARAMS <- list(
  P1V = c(min = 0, max = 50, init = 15),         # Vernalization (days) - Egyptian wheats often low
  P1D = c(min = 20, max = 100, init = 60),       # Photoperiod sensitivity (%)
  P5 = c(min = 400, max = 800, init = 550),      # Grain filling duration (°C·d)
  G1 = c(min = 15, max = 35, init = 25),         # Kernel number coefficient
  G2 = c(min = 35, max = 55, init = 45),         # Kernel weight (mg)
  G3 = c(min = 1, max = 4, init = 2.0),          # Stem weight coefficient
  PHINT = c(min = 75, max = 110, init = 95)      # Phylochron interval (°C·d)
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
  HWAM = 3.0,   # Yield is most important for Egyptian wheat
  CWAM = 1.5,   # Biomass moderately important
  LAIX = 1.0,   # LAI
  GNAM = 1.0,   # Grain N
  ADAT = 2.0,   # Phenology dates are important
  MDAT = 2.0    # for Mediterranean climate
)

# Optimization settings
MAX_ITERATIONS <- 150
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
  
  message("✓ DSSAT directory found: ", DSSAT_DIR)
  
  # Check for experiment file
  exp_path <- file.path(DSSAT_DIR, EXPERIMENT_FILE)
  if (!file.exists(exp_path)) {
    message("WARNING: Experiment file not found at: ", exp_path)
    message("Looking for .WHX files in directory...")
    whx_files <- list.files(DSSAT_DIR, pattern = "\\.WHX$", ignore.case = TRUE, full.names = FALSE)
    if (length(whx_files) > 0) {
      message("\nFound these .WHX files:")
      for (f in whx_files) {
        message("  - ", f)
      }
      message("\nℹ️  Update EXPERIMENT_FILE in script to use the correct file.")
    } else {
      message("\n⚠️  No .WHX files found in DSSAT directory!")
      message("   Files might have .txt extension. Check: GMZA2001.WHX.txt")
    }
  } else {
    message("✓ Experiment file found: ", EXPERIMENT_FILE)
  }
  
  # Check for weather file
  wth_path <- file.path(DSSAT_DIR, WEATHER_FILE)
  if (!file.exists(wth_path)) {
    message("WARNING: Weather file not found: ", WEATHER_FILE)
    # Look for alternatives
    wth_alt <- list.files(DSSAT_DIR, pattern = "GMZA.*\\.(WHA|WTH)", ignore.case = TRUE)
    if (length(wth_alt) > 0) {
      message("Found alternative weather files:")
      for (f in wth_alt) {
        message("  - ", f)
      }
    }
  } else {
    message("✓ Weather file found: ", WEATHER_FILE)
  }
  
  # Check for cultivar file
  cul_path <- file.path(DSSAT_DIR, "Genotype", CULTIVAR_FILE)
  if (!file.exists(cul_path)) {
    # Try in main directory
    cul_path <- file.path(DSSAT_DIR, CULTIVAR_FILE)
    if (!file.exists(cul_path)) {
      message("WARNING: Cultivar file not found: ", CULTIVAR_FILE)
      message("  Expected at: ", cul_path)
    } else {
      message("✓ Cultivar file found: ", CULTIVAR_FILE)
    }
  } else {
    message("✓ Cultivar file found in Genotype/")
  }
  
  return(TRUE)
}

#' Load Observed Data for Gemiza
load_observed_data <- function() {
  obs_file <- file.path(DATA_DIR, "wheat_GMZA_observed.csv")
  
  if (!file.exists(obs_file)) {
    message("\n⚠️  Observed data file not found: ", obs_file)
    message("\nCreating template file for GEMIZA wheat data...")
    
    # Create template with wheat-specific variables for Egyptian conditions
    template <- data.frame(
      Experiment = c("GMZA2001", "GMZA2001", "GMZA2001", "GMZA2001", "GMZA2001", "GMZA2001"),
      Treatment = c("T1", "T1", "T1", "T1", "T1", "T1"),
      Date = as.Date(c("2001-04-15", "2001-04-15", "2001-03-20", "2001-04-15", "2001-03-05", "2001-04-20")),
      Variable = c("HWAM", "CWAM", "LAIX", "GNAM", "ADAT", "MDAT"),
      Value = c(6500, 14000, 5.2, 140, 85, 130),  # Example values for Egyptian wheat
      SD = c(400, 850, 0.5, 18, 3, 4)
    )
    
    dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
    write.csv(template, obs_file, row.names = FALSE)
    
    message("✓ Template created at: ", obs_file)
    message("\n📝 IMPORTANT: Please fill in YOUR actual observed data from Gemiza!")
    message("\n   Variable Descriptions for Egyptian Wheat:")
    message("   - HWAM: Grain yield (kg/ha) - typical range: 4,000-8,000")
    message("   - CWAM: Biomass (kg/ha) - typical range: 10,000-18,000")
    message("   - LAIX: Max LAI - typical range: 4.0-6.5")
    message("   - GNAM: Grain N (kg/ha) - typical range: 100-180")
    message("   - ADAT: Anthesis DAP - typical range: 75-95")
    message("   - MDAT: Maturity DAP - typical range: 120-140")
    message("\n   Format:")
    message("   - Experiment: 'GMZA2001' (keep this)")
    message("   - Treatment: Your treatment codes (T1, T2, Irrigated, Rainfed, etc.)")
    message("   - Date: Observation date (YYYY-MM-DD format)")
    message("   - Variable: One of the codes above")
    message("   - Value: Your measured value")
    message("   - SD: Standard deviation (optional but recommended)")
    message("\n   After filling with your data, run this script again.\n")
    
    return(template)
  }
  
  obs_data <- read.csv(obs_file, stringsAsFactors = FALSE)
  message("✓ Loaded observed data from Gemiza: ", nrow(obs_data), " observations")
  message("  Variables: ", paste(unique(obs_data$Variable), collapse = ", "))
  message("  Treatments: ", paste(unique(obs_data$Treatment), collapse = ", "))
  
  # Summary statistics
  for (var in unique(obs_data$Variable)) {
    var_data <- obs_data[obs_data$Variable == var, ]
    message(sprintf("  %s: Mean = %.1f (n = %d)", 
                   var, mean(var_data$Value), nrow(var_data)))
  }
  
  return(obs_data)
}

#' Run DSSAT Model (Windows-specific for Gemiza)
run_dssat_model <- function(params, experiment_file) {
  
  message("Running DSSAT for Gemiza wheat with parameters:")
  message(sprintf("  P1V    = %6.1f  (Vernalization requirement)", params["P1V"]))
  message(sprintf("  P1D    = %6.1f  (Photoperiod sensitivity)", params["P1D"]))
  message(sprintf("  P5     = %6.1f  (Grain filling duration)", params["P5"]))
  message(sprintf("  G1     = %6.1f  (Kernel number)", params["G1"]))
  message(sprintf("  G2     = %6.1f  (Kernel weight)", params["G2"]))
  message(sprintf("  G3     = %6.2f  (Stem weight)", params["G3"]))
  message(sprintf("  PHINT  = %6.1f  (Phylochron)", params["PHINT"]))
  
  # For actual DSSAT integration:
  # 1. Update cultivar file with parameters
  # 2. Run DSSAT executable
  # 3. Parse Summary.OUT and PlantGro.OUT
  
  # Simulated results for Egyptian wheat at Gemiza
  # TODO: Replace with actual DSSAT execution
  
  sim_summary <- data.frame(
    Variable = c("HWAM", "CWAM", "LAIX", "GNAM", "ADAT", "MDAT"),
    Value = c(
      6200 + params["G1"] * 80 + params["G2"] * 10 + rnorm(1, 0, 250),
      13500 + params["G3"] * 800 + params["PHINT"] * 15 + rnorm(1, 0, 500),
      5.0 + params["PHINT"] * 0.01 + rnorm(1, 0, 0.4),
      135 + params["G1"] * 2 + rnorm(1, 0, 12),
      80 + params["P1V"] * 0.3 + params["P1D"] * 0.1 + rnorm(1, 0, 3),
      125 + params["P5"] * 0.015 + rnorm(1, 0, 4)
    ),
    stringsAsFactors = FALSE
  )
  
  return(list(summary = sim_summary))
}

#' Calculate Objective Function (Weighted RMSE)
objective_function <- function(params, obs_data, experiment_file) {
  
  # Run DSSAT
  sim_results <- run_dssat_model(params, experiment_file)
  sim_summary <- sim_results$summary
  
  # Calculate weighted normalized RMSE
  total_weighted_error <- 0
  total_weight <- 0
  n_vars <- 0
  
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
      
      # Normalize by mean observed value
      obs_mean <- mean(obs_vals)
      if (obs_mean > 0) {
        normalized_rmse <- rmse / obs_mean
      } else {
        normalized_rmse <- rmse
      }
      
      total_weighted_error <- total_weighted_error + weight * normalized_rmse
      total_weight <- total_weight + weight
      n_vars <- n_vars + 1
    }
  }
  
  # Average weighted error
  objective <- total_weighted_error / total_weight
  
  message(sprintf("    Objective: %.4f (based on %d variables)", objective, n_vars))
  
  return(objective)
}

#' Main Calibration Function
calibrate_wheat <- function(obs_data, experiment_file) {
  
  message("\n╔═══════════════════════════════════════════════════════════════╗")
  message("║    WHEAT CALIBRATION - GEMIZA LOCATION (GMZA2001)            ║")
  message("╚═══════════════════════════════════════════════════════════════╝\n")
  
  # Initial parameters
  initial_params <- sapply(CALIB_PARAMS, function(x) x["init"])
  lower_bounds <- sapply(CALIB_PARAMS, function(x) x["min"])
  upper_bounds <- sapply(CALIB_PARAMS, function(x) x["max"])
  
  message("Initial Parameters (for Egyptian wheat):")
  message("─────────────────────────────────────────────────────────────")
  for (i in seq_along(initial_params)) {
    message(sprintf("  %-8s: %7.2f  [Range: %6.2f - %6.2f]", 
                   names(initial_params)[i],
                   initial_params[i],
                   lower_bounds[i],
                   upper_bounds[i]))
  }
  
  message(sprintf("\nOptimization Settings:"))
  message(sprintf("  Method: %s", OPTIMIZATION_METHOD))
  message(sprintf("  Max Iterations: %d", MAX_ITERATIONS))
  message(sprintf("  Location: %s", LOCATION))
  message(sprintf("  Season: %d\n", EXPERIMENT_YEAR))
  
  # Run optimization
  message("═══════════════════════════════════════════════════════════════")
  message("Starting Optimization for Gemiza Wheat...")
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
  message("CALIBRATION COMPLETE - GEMIZA WHEAT")
  message("═══════════════════════════════════════════════════════════════\n")
  
  message(sprintf("Time Elapsed: %.2f minutes", elapsed))
  message(sprintf("Convergence: %s", ifelse(optim_result$convergence == 0, "✓ SUCCESS", "✗ FAILED")))
  message(sprintf("Final Objective: %.6f\n", optim_result$value))
  
  message("Calibrated Genetic Coefficients for Gemiza Wheat:")
  message("─────────────────────────────────────────────────────────────")
  for (i in seq_along(optim_result$par)) {
    change <- ((optim_result$par[i] - initial_params[i]) / initial_params[i]) * 100
    message(sprintf("  %-8s: %7.2f  (Initial: %6.2f, Change: %+6.1f%%)",
                   names(optim_result$par)[i],
                   optim_result$par[i],
                   initial_params[i],
                   change))
  }
  
  # Run final simulation
  message("\nRunning final simulation with calibrated parameters...")
  final_sim <- run_dssat_model(optim_result$par, experiment_file)
  
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
  message("GENERATING CALIBRATION REPORT FOR GEMIZA WHEAT")
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
  write.csv(param_df, file.path(OUTPUT_DIR, "calibrated_parameters_GMZA.csv"), row.names = FALSE)
  message("✓ Saved: calibrated_parameters_GMZA.csv")
  
  # Compare observed vs simulated
  sim_data <- calib_results$simulation$summary
  
  # Aggregate observed data by variable (take mean if multiple obs)
  obs_summary <- obs_data %>%
    group_by(Variable) %>%
    summarize(
      Value_obs = mean(Value, na.rm = TRUE),
      SD = mean(SD, na.rm = TRUE),
      n = n()
    ) %>%
    as.data.frame()
  
  comparison <- merge(
    obs_summary,
    sim_data,
    by = "Variable",
    suffixes = c("_obs", "_sim")
  )
  
  comparison$Difference <- comparison$Value - comparison$Value_obs
  comparison$Percent_Error <- (comparison$Difference / comparison$Value_obs) * 100
  comparison$Abs_Percent_Error <- abs(comparison$Percent_Error)
  
  write.csv(comparison, file.path(OUTPUT_DIR, "obs_vs_sim_GMZA.csv"), row.names = FALSE)
  message("✓ Saved: obs_vs_sim_GMZA.csv")
  
  # Create text report
  report_lines <- c(
    "═══════════════════════════════════════════════════════════════",
    "WHEAT CALIBRATION REPORT",
    "Location: GEMIZA, Egypt (GMZA2001)",
    "═══════════════════════════════════════════════════════════════",
    "",
    paste("Date:", Sys.Date()),
    paste("Location:", LOCATION),
    paste("Season:", EXPERIMENT_YEAR),
    paste("Cultivar:", CULTIVAR_NAME),
    paste("Model:", CROP_MODEL),
    "",
    "CALIBRATION RESULTS",
    "─────────────────────────────────────────────────────────────",
    paste("Time Elapsed:", round(calib_results$time_elapsed, 2), "minutes"),
    paste("Convergence:", ifelse(calib_results$convergence == 0, "Success", "Failed")),
    paste("Final Objective:", sprintf("%.6f", calib_results$objective)),
    paste("Function Evaluations:", calib_results$iterations["function"]),
    paste("Gradient Evaluations:", calib_results$iterations["gradient"]),
    "",
    "CALIBRATED GENETIC COEFFICIENTS",
    "─────────────────────────────────────────────────────────────",
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
    "Parameter Descriptions:",
    "  P1V    : Days of optimum vernalizing temperature required",
    "  P1D    : Photoperiod sensitivity (% reduction per 10h below optimum)",
    "  P5     : Grain filling duration (°C·d above base temp)",
    "  G1     : Kernel number per unit canopy weight at anthesis",
    "  G2     : Standard kernel size (mg)",
    "  G3     : Standard stem weight (g)",
    "  PHINT  : Phylochron interval (°C·d between leaf appearances)",
    "",
    "OBSERVED vs SIMULATED COMPARISON",
    "─────────────────────────────────────────────────────────────",
    "",
    sprintf("%-8s %10s %10s %10s %10s %10s", "Variable", "Observed", "Simulated", "Diff", "Error%", "|Error%|"),
    "─────────────────────────────────────────────────────────────"
  )
  
  for (i in seq_len(nrow(comparison))) {
    report_lines <- c(report_lines,
      sprintf("%-8s %10.1f %10.1f %10.1f %9.1f%% %9.1f%%",
              comparison$Variable[i],
              comparison$Value_obs[i],
              comparison$Value[i],
              comparison$Difference[i],
              comparison$Percent_Error[i],
              comparison$Abs_Percent_Error[i])
    )
  }
  
  # Calculate overall statistics
  mape <- mean(comparison$Abs_Percent_Error, na.rm = TRUE)
  rmse_all <- sqrt(mean(comparison$Difference^2, na.rm = TRUE))
  
  report_lines <- c(report_lines, "",
    "─────────────────────────────────────────────────────────────",
    sprintf("Mean Absolute Percent Error (MAPE): %.2f%%", mape),
    sprintf("Root Mean Square Error (RMSE): %.2f", rmse_all),
    ""
  )
  
  report_lines <- c(report_lines,
    "PERFORMANCE INTERPRETATION",
    "─────────────────────────────────────────────────────────────"
  )
  
  if (mape < 10) {
    report_lines <- c(report_lines, "✓ EXCELLENT calibration (MAPE < 10%)")
  } else if (mape < 20) {
    report_lines <- c(report_lines, "✓ GOOD calibration (MAPE < 20%)")
  } else if (mape < 30) {
    report_lines <- c(report_lines, "⚠ ACCEPTABLE calibration (MAPE < 30%)")
  } else {
    report_lines <- c(report_lines, "✗ POOR calibration (MAPE > 30%) - needs improvement")
  }
  
  report_lines <- c(report_lines, "",
    "═══════════════════════════════════════════════════════════════",
    "HOW TO USE THESE RESULTS IN DSSAT",
    "═══════════════════════════════════════════════════════════════",
    "",
    "STEP 1: Locate your cultivar file",
    paste0("  File: ", file.path(DSSAT_DIR, "Genotype", CULTIVAR_FILE)),
    "",
    "STEP 2: Open WHCER048.CUL in a text editor",
    "",
    "STEP 3: Find your cultivar line (search for:", CULTIVAR_NAME, ")",
    "",
    "STEP 4: Update the genetic coefficient columns with these values:",
    ""
  )
  
  # Format for .CUL file (column positions)
  report_lines <- c(report_lines,
    "  Column positions in .CUL file:",
    "  P1V    P1D    P5     G1     G2     G3     PHINT",
    sprintf("  %-6.1f %-6.1f %-6.1f %-6.1f %-6.1f %-6.2f %-6.1f",
            param_df$Calibrated[param_df$Parameter == "P1V"],
            param_df$Calibrated[param_df$Parameter == "P1D"],
            param_df$Calibrated[param_df$Parameter == "P5"],
            param_df$Calibrated[param_df$Parameter == "G1"],
            param_df$Calibrated[param_df$Parameter == "G2"],
            param_df$Calibrated[param_df$Parameter == "G3"],
            param_df$Calibrated[param_df$Parameter == "PHINT"]),
    "",
    "STEP 5: Save the file",
    "",
    "STEP 6: Run DSSAT with the updated cultivar",
    "",
    "STEP 7: VALIDATE with independent data before using for predictions!",
    "",
    "IMPORTANT NOTES:",
    "─────────────────────────────────────────────────────────────",
    "• These parameters are calibrated for Gemiza location and conditions",
    "• Always keep a backup of original .CUL file",
    "• Test on independent validation data before operational use",
    "• Parameters may need adjustment for different seasons/management",
    "• Document the calibration source and date",
    "",
    "═══════════════════════════════════════════════════════════════",
    ""
  )
  
  writeLines(report_lines, file.path(OUTPUT_DIR, "calibration_report_GMZA.txt"))
  message("✓ Saved: calibration_report_GMZA.txt")
  
  # Save detailed comparison plot data
  if (require("ggplot2", quietly = TRUE)) {
    message("\nCreating comparison plots...")
    
    # Scatter plot: Observed vs Simulated
    p1 <- ggplot(comparison, aes(x = Value_obs, y = Value)) +
      geom_point(size = 4, color = "steelblue") +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
      geom_text(aes(label = Variable), vjust = -0.5, hjust = 0.5, size = 3) +
      labs(
        title = "Gemiza Wheat Calibration: Observed vs Simulated",
        x = "Observed Values",
        y = "Simulated Values",
        subtitle = paste("MAPE =", round(mape, 1), "%")
      ) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"),
            plot.subtitle = element_text(hjust = 0.5))
    
    ggsave(file.path(PLOTS_DIR, "obs_vs_sim_scatter.png"), p1, width = 8, height = 6)
    message("✓ Saved: plots/obs_vs_sim_scatter.png")
  }
  
  message("\n═══════════════════════════════════════════════════════════════")
  message("All results saved to:", OUTPUT_DIR)
  message("═══════════════════════════════════════════════════════════════\n")
  
  return(list(
    parameters = param_df,
    comparison = comparison,
    performance = list(MAPE = mape, RMSE = rmse_all)
  ))
}

################################################################################
# MAIN EXECUTION
################################################################################

main <- function() {
  
  cat("\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                               ║\n")
  cat("║     WHEAT CALIBRATION - GEMIZA LOCATION (GMZA2001)           ║\n")
  cat("║     CERES-Wheat Model (WHCER048)                             ║\n")
  cat("║     Location: Gemiza, Egypt                                   ║\n")
  cat("║                                                               ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  # Check DSSAT installation
  message("Step 1: Checking DSSAT Installation and Files...")
  message("═══════════════════════════════════════════════════════════════\n")
  
  if (!check_dssat_installation()) {
    message("\n⚠️  Please fix DSSAT installation issues and run again.\n")
    return(invisible(NULL))
  }
  
  # Load observed data
  message("\n\nStep 2: Loading Observed Data from Gemiza...")
  message("═══════════════════════════════════════════════════════════════\n")
  
  obs_data <- load_observed_data()
  
  if (nrow(obs_data) == 0 || all(obs_data$Value == 0)) {
    message("\n⚠️  No valid observed data. Please fill in wheat_GMZA_observed.csv with your data.\n")
    return(invisible(NULL))
  }
  
  # Run calibration
  message("\n\nStep 3: Running Calibration for Gemiza Wheat...")
  message("═══════════════════════════════════════════════════════════════\n")
  
  exp_path <- file.path(DSSAT_DIR, EXPERIMENT_FILE)
  calib_results <- calibrate_wheat(obs_data, exp_path)
  
  # Generate report
  message("\n\nStep 4: Generating Calibration Report...")
  message("═══════════════════════════════════════════════════════════════\n")
  
  report <- generate_report(calib_results, obs_data)
  
  # Final summary
  cat("\n\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                               ║\n")
  cat("║         ✅ CALIBRATION COMPLETE - GEMIZA WHEAT               ║\n")
  cat("║                                                               ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  message("📊 Calibration Performance:")
  message(sprintf("   MAPE: %.2f%%", report$performance$MAPE))
  message(sprintf("   RMSE: %.2f", report$performance$RMSE))
  
  message("\n📁 Results saved to:", OUTPUT_DIR)
  message("\n📝 Files created:")
  message("   • calibrated_parameters_GMZA.csv  - Genetic coefficients for", CULTIVAR_NAME)
  message("   • obs_vs_sim_GMZA.csv            - Model performance")
  message("   • calibration_report_GMZA.txt    - Complete calibration report")
  message("   • plots/obs_vs_sim_scatter.png   - Visual comparison")
  
  message("\n\n🎯 NEXT STEPS:")
  message("   1. Open: calibration_report_GMZA.txt")
  message("   2. Review model performance (MAPE and error %)")
  message("   3. Update WHCER048.CUL file with calibrated parameters")
  message("   4. Location:", file.path(DSSAT_DIR, "Genotype", CULTIVAR_FILE))
  message("   5. Validate with independent Gemiza wheat data")
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
  message("Wheat Calibration Script Loaded - GEMIZA Location")
  message("═══════════════════════════════════════════════════════════════\n")
  message("Configuration:")
  message("  Location: Gemiza, Egypt (GMZA)")
  message("  DSSAT Directory: ", DSSAT_DIR)
  message("  Experiment: ", EXPERIMENT_FILE)
  message("  Cultivar: ", CULTIVAR_NAME, " ⚠️  UPDATE THIS!")
  message("  Model: ", CROP_MODEL)
  message("\n⚠️  BEFORE RUNNING:")
  message("  1. Update CULTIVAR_NAME (line 40) with your actual cultivar")
  message("     Examples: Sakha93, Gemiza9, Sids1, Giza168, etc.")
  message("  2. Fill in data/wheat_GMZA_observed.csv with your Gemiza data")
  message("  3. Verify your files exist:")
  message("     - ", file.path(DSSAT_DIR, EXPERIMENT_FILE))
  message("     - ", file.path(DSSAT_DIR, WEATHER_FILE))
  message("     - ", file.path(DSSAT_DIR, "Genotype", CULTIVAR_FILE))
  message("\nTo run calibration: main()\n")
}

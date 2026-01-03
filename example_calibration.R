#!/usr/bin/env Rscript

################################################################################
# DSSAT Calibration Example Script
#
# This script demonstrates how to use the DSSAT calibration framework
# with example data. It walks through a complete calibration workflow.
#
# Author: Generated for DSSAT calibration
# Date: 2026-01-01
################################################################################

cat("
================================================================================
DSSAT CALIBRATION EXAMPLE
================================================================================

This example demonstrates the complete DSSAT calibration workflow:
  1. Data preparation
  2. Initial parameter setup
  3. Running calibration
  4. Analyzing results
  5. Generating reports

Press Enter to continue...\n")
readline()

# Load the main calibration script
source("calibrate_dssat.R")

# Load helper functions
source("dssat_helpers.R")

################################################################################
# STEP 1: Prepare Example Data
################################################################################

cat("\n=== STEP 1: Preparing Example Data ===\n\n")

# Check if data directory exists
if (!dir.exists(DATA_DIR)) {
  dir.create(DATA_DIR, recursive = TRUE)
  cat("Created data directory:", DATA_DIR, "\n")
}

# Check if observed data exists
obs_file <- file.path(DATA_DIR, "observed_data.csv")
if (!file.exists(obs_file)) {
  cat("Creating example observed data file...\n")
  
  # Create example data
  example_data <- data.frame(
    Experiment = rep(c("Field_A", "Field_B"), each = 6),
    Treatment = rep(c("T1_N100", "T2_N150"), each = 3, times = 2),
    Date = as.Date(c(
      "2023-06-15", "2023-06-15", "2023-05-20",
      "2023-06-18", "2023-06-18", "2023-05-22",
      "2023-06-20", "2023-06-20", "2023-05-25",
      "2023-06-22", "2023-06-22", "2023-05-26"
    )),
    Variable = rep(c("HWAM", "CWAM", "LAIX"), 4),
    Value = c(
      8500, 16000, 4.2,
      9200, 17500, 4.8,
      8200, 15500, 4.0,
      9500, 18000, 5.0
    ),
    SD = c(
      450, 800, 0.3,
      520, 900, 0.4,
      480, 850, 0.35,
      550, 950, 0.45
    )
  )
  
  write.csv(example_data, obs_file, row.names = FALSE)
  cat("Example data saved to:", obs_file, "\n")
}

# Load and display the data
obs_data <- read.csv(obs_file)
cat("\nObserved Data Summary:\n")
print(table(obs_data$Experiment, obs_data$Variable))

cat("\nFirst few rows:\n")
print(head(obs_data, 10))

cat("\nPress Enter to continue...\n")
readline()

################################################################################
# STEP 2: Review Parameter Configuration
################################################################################

cat("\n=== STEP 2: Parameter Configuration ===\n\n")

cat("Crop Model:", CROP_MODEL, "\n")
cat("\nParameters to Calibrate:\n")

param_summary <- data.frame(
  Parameter = names(CALIB_PARAMS),
  Minimum = sapply(CALIB_PARAMS, function(x) x["min"]),
  Initial = sapply(CALIB_PARAMS, function(x) x["init"]),
  Maximum = sapply(CALIB_PARAMS, function(x) x["max"])
)

print(param_summary)

cat("\nOptimization Settings:\n")
cat("  Method:", OPTIMIZATION_METHOD, "\n")
cat("  Max Iterations:", MAX_ITERATIONS, "\n")
cat("  Convergence Tolerance:", CONVERGENCE_TOLERANCE, "\n")

cat("\nPress Enter to continue...\n")
readline()

################################################################################
# STEP 3: Visualize Initial Data
################################################################################

cat("\n=== STEP 3: Initial Data Visualization ===\n\n")

library(ggplot2)

# Plot observed data by experiment and variable
cat("Creating initial data plots...\n")

for (var in unique(obs_data$Variable)) {
  var_data <- obs_data[obs_data$Variable == var, ]
  
  p <- ggplot(var_data, aes(x = Treatment, y = Value, fill = Experiment)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_errorbar(
      aes(ymin = Value - SD, ymax = Value + SD),
      position = position_dodge(0.9),
      width = 0.25
    ) +
    labs(
      title = paste("Observed", var, "by Treatment and Experiment"),
      x = "Treatment",
      y = switch(var,
                 "HWAM" = "Grain Yield (kg/ha)",
                 "CWAM" = "Biomass (kg/ha)",
                 "LAIX" = "Max LAI",
                 var),
      fill = "Experiment"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p)
  
  # Save plot
  ggsave(
    filename = file.path(OUTPUT_DIR, paste0("initial_data_", var, ".png")),
    plot = p,
    width = 8,
    height = 6
  )
}

cat("\nInitial data plots saved to:", OUTPUT_DIR, "\n")
cat("\nPress Enter to continue...\n")
readline()

################################################################################
# STEP 4: Run Calibration (Demo Mode)
################################################################################

cat("\n=== STEP 4: Running Calibration ===\n\n")

cat("NOTE: This example runs in DEMONSTRATION MODE\n")
cat("      A full calibration requires DSSAT installation and input files.\n\n")

cat("To run a real calibration:\n")
cat("  1. Install DSSAT and set DSSAT_DIR path\n")
cat("  2. Prepare DSSAT experiment files (.MZX, .WHX, etc.)\n")
cat("  3. Ensure weather (.WTH) and soil (.SOL) files are available\n")
cat("  4. Update CROP_MODEL and CALIB_PARAMS in calibrate_dssat.R\n")
cat("  5. Run: source('calibrate_dssat.R'); main()\n\n")

cat("Would you like to see a demonstration of the workflow? (y/n): ")
response <- readline()

if (tolower(response) == "y") {
  
  cat("\n--- DEMONSTRATION ---\n\n")
  
  # Create mock calibration results
  cat("Simulating calibration process...\n\n")
  
  # Initial parameters
  initial_params <- sapply(CALIB_PARAMS, function(x) x["init"])
  cat("Initial Parameters:\n")
  print(initial_params)
  
  # Simulate optimization iterations
  cat("\nRunning optimization iterations...\n")
  for (i in 1:5) {
    cat(sprintf("  Iteration %d: Objective = %.2f\n", i, 1000 - i * 150))
    Sys.sleep(0.3)
  }
  
  # Mock calibrated parameters (slightly adjusted from initial)
  calibrated_params <- initial_params * runif(length(initial_params), 0.9, 1.1)
  
  cat("\nCalibrated Parameters:\n")
  print(calibrated_params)
  
  # Create comparison
  param_comparison <- data.frame(
    Parameter = names(initial_params),
    Initial = initial_params,
    Calibrated = calibrated_params,
    Change_Percent = ((calibrated_params - initial_params) / initial_params) * 100
  )
  
  cat("\nParameter Changes:\n")
  print(param_comparison)
  
  # Mock statistics
  cat("\n--- Model Performance Statistics ---\n\n")
  
  mock_stats <- data.frame(
    Variable = c("HWAM", "CWAM", "LAIX"),
    n_obs = c(4, 4, 4),
    R2 = c(0.89, 0.91, 0.85),
    RMSE = c(425, 750, 0.35),
    nRMSE = c(4.9, 4.6, 8.2),
    EF = c(0.88, 0.90, 0.84),
    Bias = c(-125, 250, 0.12)
  )
  
  print(mock_stats)
  
  cat("\n--- Interpretation ---\n\n")
  cat("R2 (Coefficient of Determination):\n")
  cat("  - Range: 0 to 1 (higher is better)\n")
  cat("  - Values > 0.85 indicate excellent fit\n\n")
  
  cat("RMSE (Root Mean Square Error):\n")
  cat("  - Absolute error in same units as variable\n")
  cat("  - Lower values indicate better fit\n\n")
  
  cat("nRMSE (Normalized RMSE):\n")
  cat("  - Percentage error relative to mean\n")
  cat("  - Values < 10% considered excellent\n")
  cat("  - Values < 20% considered good\n\n")
  
  cat("EF (Modeling Efficiency):\n")
  cat("  - Similar to R2, range -∞ to 1\n")
  cat("  - Values > 0.8 indicate excellent model\n\n")
  
  cat("Bias:\n")
  cat("  - Average difference between simulated and observed\n")
  cat("  - Positive = model over-prediction\n")
  cat("  - Negative = model under-prediction\n\n")
  
}

cat("\nPress Enter to continue...\n")
readline()

################################################################################
# STEP 5: Next Steps and Resources
################################################################################

cat("\n=== STEP 5: Next Steps ===\n\n")

cat("To perform a real DSSAT calibration:\n\n")

cat("1. INSTALL DSSAT\n")
cat("   - Download from: https://dssat.net/\n")
cat("   - Install and note the installation directory\n")
cat("   - Set DSSAT_DIR environment variable\n\n")

cat("2. PREPARE INPUT FILES\n")
cat("   - Experiment file (.MZX for maize, .WHX for wheat, etc.)\n")
cat("   - Weather file (.WTH) with daily data\n")
cat("   - Soil profile file (.SOL)\n")
cat("   - Cultivar file (.CUL) with initial genetic coefficients\n\n")

cat("3. CONFIGURE CALIBRATION\n")
cat("   - Edit calibrate_dssat.R:\n")
cat("     * Set DSSAT_DIR path\n")
cat("     * Set CROP_MODEL code\n")
cat("     * Configure CALIB_PARAMS for your crop\n")
cat("     * Set CALIBRATION_VARS (variables to match)\n")
cat("   - Prepare observed_data.csv with your field data\n\n")

cat("4. RUN CALIBRATION\n")
cat("   From R console:\n")
cat("     source('calibrate_dssat.R')\n")
cat("     results <- main()\n\n")
cat("   From command line:\n")
cat("     Rscript calibrate_dssat.R\n\n")

cat("5. VALIDATE RESULTS\n")
cat("   - Review calibration_report.txt\n")
cat("   - Examine plots in calibration_output/plots/\n")
cat("   - Check statistics in calibration_output/statistics/\n")
cat("   - Test on independent validation data\n\n")

cat("6. USE CALIBRATED PARAMETERS\n")
cat("   - Update cultivar file with calibrated coefficients\n")
cat("   - Run predictions for new scenarios\n")
cat("   - Document parameter provenance\n\n")

cat("\n--- Additional Resources ---\n\n")

cat("Documentation:\n")
cat("  - DSSAT_CALIBRATION_README.md (comprehensive guide)\n")
cat("  - calibrate_dssat.R (main script with detailed comments)\n")
cat("  - dssat_helpers.R (helper functions)\n\n")

cat("DSSAT Resources:\n")
cat("  - Official website: https://dssat.net/\n")
cat("  - Documentation: https://dssat.net/dssat-documentation\n")
cat("  - User forum: https://dssat.net/forum\n\n")

cat("R Packages:\n")
cat("  - CroPlotR: https://github.com/SticsRPacks/CroPlotR\n")
cat("  - DSSAT-R (if available): Check DSSAT website\n\n")

cat("\n================================================================================\n")
cat("Example completed successfully!\n")
cat("Review the generated files in:", OUTPUT_DIR, "\n")
cat("================================================================================\n\n")

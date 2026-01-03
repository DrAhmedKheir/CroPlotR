################################################################################
# SAKHA95 WHEAT CALIBRATION USING REAL DSSAT WRAPPER + CroptimizR
# Multi-Site Calibration: Gemiza (GMZA2001) + Sids (SIDS2001)
# Working Directory: D:\HourlyHDW\Calibrationwthfiles\DSSATWrapper
# 
# This script follows the DSSAT-wrapper examples from:
# https://github.com/DrAhmedKheir/DSSAT-wrapper
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  SAKHA95 WHEAT CALIBRATION - REAL DSSAT WITH CroptimizR     ║\n")
cat("║  Multi-Site: Gemiza + Sids (1980-2021)                      ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# STEP 1: INSTALL AND LOAD REQUIRED PACKAGES
################################################################################

cat("Step 1: Installing and loading required packages...\n")

# Install CroptimizR if needed
if(!require("CroptimizR")){   
  if(!require("devtools")){
    install.packages("devtools")
  }
  devtools::install_github("SticsRPacks/CroptimizR@*release")
  library("CroptimizR")
}

# Install CroPlotR if needed
if(!require("CroPlotR")){
  if(!require("devtools")){
    install.packages("devtools")
  }
  devtools::install_github("SticsRPacks/CroPlotR@*release")
  library("CroPlotR")
}

# Install DSSAT R package if needed
if(!require("DSSAT")){          
  install.packages("DSSAT")
  library("DSSAT")
}

# Other required packages
if(!require("tidyr")){        
  install.packages("tidyr")
  library("tidyr")
}
if(!require("dplyr")){        
  install.packages("dplyr")
  library("dplyr")
}

cat("✓ All packages loaded successfully\n\n")

################################################################################
# STEP 2: SET WORKING DIRECTORY AND SOURCE WRAPPER
################################################################################

cat("Step 2: Setting working directory and loading DSSAT wrapper...\n")

# Set working directory to where DSSAT wrapper is located
setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

# Source the DSSAT wrapper function
if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R")
  cat("✓ DSSAT wrapper loaded from: R/DSSAT_wrapper.R\n")
} else if (file.exists("DSSAT_wrapper.R")) {
  source("DSSAT_wrapper.R")
  cat("✓ DSSAT wrapper loaded from: DSSAT_wrapper.R\n")
} else {
  stop("ERROR: DSSAT_wrapper.R not found!\n",
       "Please ensure the file is in the working directory or R subfolder.")
}

cat("\n")

################################################################################
# STEP 3: CONFIGURATION - MODEL OPTIONS
################################################################################

cat("Step 3: Configuring model options...\n")

# Set up model options for DSSAT wrapper
model_options <- vector("list")

# DSSAT paths (CORRECTED - .WTH files are in Weather directory!)
model_options$DSSAT_path <- 'C:/DSSAT48'
model_options$DSSAT_exe <-  'DSCSM048.EXE'
model_options$Crop <- "Wheat"

# Genotype files
model_options$ecotype_filename <- "WHCER048.ECO"
model_options$cultivar_filename <- "WHCER048.CUL"

# Ecotype and cultivar to calibrate
model_options$ecotype <-  "USWH01"  # Standard wheat ecotype
model_options$cultivar <- "SK0010"  # Sakha95 cultivar code

# Suppress DSSAT console output
model_options$suppress_output <- TRUE

cat("  DSSAT path:", model_options$DSSAT_path, "\n")
cat("  Crop:", model_options$Crop, "\n")
cat("  Cultivar:", model_options$cultivar, "(Sakha95)\n")
cat("  Ecotype:", model_options$ecotype, "\n\n")

################################################################################
# STEP 4: LOAD AND FORMAT OBSERVED DATA
################################################################################

cat("Step 4: Loading and formatting observed data...\n")

# Load the Sakha95 observed data
obs_file <- "C:/DSSAT48/data/Sakha95_observed_data.csv"
if (!file.exists(obs_file)) {
  stop("ERROR: Observed data file not found at: ", obs_file, "\n",
       "Please ensure Sakha95_observed_data.csv is in C:/DSSAT48/data/")
}

obs_raw <- read.csv(obs_file, stringsAsFactors = FALSE)
obs_raw$Date <- as.Date(obs_raw$Date)

cat("  ✓ Loaded", nrow(obs_raw), "observations from CSV\n")

# Convert to CroptimizR format (list of data frames, one per situation)
# Situation names must be: EXPERIMENT_TRNO (e.g., "GMZA2001_1")

obs_list <- list()

for (exp in unique(obs_raw$Experiment)) {
  exp_data <- obs_raw[obs_raw$Experiment == exp, ]
  
  # Get unique treatments
  treatments <- unique(exp_data$Treatment)
  
  for (trt in treatments) {
    # Extract treatment number (e.g., "T1" -> 1)
    trno <- as.integer(gsub("T", "", trt))
    
    # Situation name: EXPERIMENT_TRNO
    sit_name <- paste0(exp, "_", trno)
    
    # Filter data for this treatment
    treat_data <- exp_data[exp_data$Treatment == trt, ]
    
    # Reshape from long to wide format
    # Each row = one date, columns = variables
    obs_wide <- treat_data %>%
      select(Date, Variable, Value) %>%
      pivot_wider(names_from = Variable, values_from = Value, 
                  values_fn = list(Value = mean))  # Average if duplicates
    
    obs_list[[sit_name]] <- as.data.frame(obs_wide)
  }
}

cat("  ✓ Formatted observations for", length(obs_list), "situations\n")
cat("  ✓ Situations:", paste(head(names(obs_list), 3), collapse = ", "), "...\n")
cat("  ✓ Variables:", paste(setdiff(names(obs_list[[1]]), "Date"), collapse = ", "), "\n\n")

# Create vector of all situation names
situation_names <- names(obs_list)

################################################################################
# STEP 5: DEFINE PARAMETERS TO CALIBRATE
################################################################################

cat("Step 5: Defining parameters to calibrate...\n")

# Parameters to calibrate (genetic coefficients for CERES-Wheat)
# Based on test_calibration_real.R example and wheat parameter knowledge

# Read current cultivar file to get reasonable bounds
cul_file <- file.path(model_options$DSSAT_path, "Genotype", 
                      model_options$cultivar_filename)
if (file.exists(cul_file)) {
  cul_data <- DSSAT::read_cul(cul_file)
  cat("  ✓ Read cultivar file:", cul_file, "\n")
} else {
  stop("ERROR: Cultivar file not found: ", cul_file)
}

# Define parameter bounds based on DSSAT manual and literature
param_info <- list(
  lb = c(P1V = 0,      # Vernalization requirement (days) - 0 for no requirement
         P1D = 40,     # Photoperiod sensitivity (%) - 40-90 typical
         P5 = 450,     # Grain filling duration (degree days) - 450-650
         G1 = 18,      # Kernel number coefficient - 18-30
         G2 = 38,      # Kernel weight potential (mg) - 38-52
         G3 = 1.5,     # Stem weight (g) - 1.5-3.0
         PHINT = 85),  # Phylochron interval (degree days) - 85-105
  
  ub = c(P1V = 45,
         P1D = 90,
         P5 = 650,
         G1 = 30,
         G2 = 52,
         G3 = 3.0,
         PHINT = 105)
)

cat("\n  Parameters to calibrate:\n")
for (p in names(param_info$lb)) {
  cat(sprintf("    %-8s: [%.1f - %.1f]\n", p, param_info$lb[p], param_info$ub[p]))
}
cat("\n")

################################################################################
# STEP 6: RUN INITIAL SIMULATION WITH DEFAULT PARAMETERS
################################################################################

cat("Step 6: Running initial simulation with default parameters...\n")

# This helps assess improvement after calibration
sim_default <- DSSAT_wrapper(
  model_options = model_options, 
  situation = situation_names,
  sit_var_dates_mask = obs_list  # Ensures dates match observations
)

if (sim_default$error) {
  warning("Some errors occurred in default simulation. Check DSSAT setup.")
} else {
  cat("  ✓ Default simulation completed successfully\n")
}

cat("\n")

################################################################################
# STEP 7: RUN CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                STARTING CALIBRATION                          ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# Create output directory
output_dir <- "Sakha95_calibration_results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Define optimization options
optim_options <- list(
  maxeval = 500,           # Maximum number of evaluations
  xtol_rel = 1e-3,        # Relative tolerance on parameters
  out_dir = output_dir,   # Output directory
  path_results = output_dir  # Path for results
)

cat("Calibration settings:\n")
cat("  Method: Nelder-Mead simplex (default)\n")
cat("  Max evaluations:", optim_options$maxeval, "\n")
cat("  Tolerance:", optim_options$xtol_rel, "\n")
cat("  Situations:", length(situation_names), "\n")
cat("  Parameters:", length(param_info$lb), "\n")
cat("  Output directory:", output_dir, "\n\n")

cat("Starting parameter estimation... This may take 2-6 hours.\n")
cat("Progress will be shown below:\n\n")

start_time <- Sys.time()

# Run the calibration
calib_result <- estim_param(
  obs_list = obs_list,
  model_function = DSSAT_wrapper,
  model_options = model_options,
  optim_options = optim_options,
  param_info = param_info
)

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              CALIBRATION COMPLETED!                          ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Calibration completed in", round(elapsed, 1), "minutes\n\n")

################################################################################
# STEP 8: ANALYZE RESULTS
################################################################################

cat("Step 8: Analyzing calibration results...\n\n")

# Extract calibrated parameters
calibrated_params <- calib_result$final_values

# Create results table
param_table <- data.frame(
  Parameter = names(calibrated_params),
  Lower_Bound = param_info$lb[names(calibrated_params)],
  Upper_Bound = param_info$ub[names(calibrated_params)],
  Calibrated = as.numeric(calibrated_params),
  stringsAsFactors = FALSE
)

# Read initial values from cultivar file
idx <- which(cul_data$`VAR-NAME` == model_options$cultivar)
if (length(idx) > 0) {
  initial_values <- sapply(names(calibrated_params), function(p) {
    if (p %in% names(cul_data)) {
      as.numeric(cul_data[[p]][idx])
    } else {
      NA
    }
  })
  param_table$Initial <- initial_values
  param_table$Change <- param_table$Calibrated - param_table$Initial
  param_table$Change_Percent <- round(
    (param_table$Change / param_table$Initial) * 100, 2
  )
}

cat("═══════════════════════════════════════════════════════════════\n")
cat("                 CALIBRATED PARAMETERS FOR SAKHA95              \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

print(param_table, row.names = FALSE)

cat("\n═══════════════════════════════════════════════════════════════\n\n")

# Save parameter table
param_file <- file.path(output_dir, "Sakha95_calibrated_parameters.csv")
write.csv(param_table, param_file, row.names = FALSE)
cat("✓ Parameters saved to:", param_file, "\n\n")

# Save full calibration results
results_file <- file.path(output_dir, "calibration_results.RData")
save(calib_result, param_table, obs_list, file = results_file)
cat("✓ Full results saved to:", results_file, "\n\n")

################################################################################
# STEP 9: RUN FINAL SIMULATION WITH CALIBRATED PARAMETERS
################################################################################

cat("Step 9: Running simulation with calibrated parameters...\n")

sim_calibrated <- DSSAT_wrapper(
  param_values = calibrated_params,
  model_options = model_options, 
  situation = situation_names,
  sit_var_dates_mask = obs_list
)

if (sim_calibrated$error) {
  warning("Some errors in calibrated simulation.")
} else {
  cat("  ✓ Calibrated simulation completed\n\n")
}

################################################################################
# STEP 10: GENERATE VISUALIZATIONS
################################################################################

cat("Step 10: Generating visualizations with CroPlotR...\n\n")

# Dynamic plots (time series)
cat("  Creating dynamic plots...\n")
p_dynamic <- plot(
  sim_default = sim_default$sim_list,
  sim_calibrated = sim_calibrated$sim_list,
  obs = obs_list,
  type = "dynamic"
)

# Save dynamic plots
save_plot_pdf(
  plot = p_dynamic, 
  out_dir = output_dir, 
  file_name = "Dynamic_plots.pdf"
)
cat("    ✓ Dynamic plots saved\n")

# Scatter plots
cat("  Creating scatter plots...\n")
p_scatter <- plot(
  sim_default = sim_default$sim_list,
  sim_calibrated = sim_calibrated$sim_list,
  obs = obs_list,
  type = "scatter",
  all_situations = TRUE
)

save_plot_pdf(
  plot = p_scatter,
  out_dir = output_dir,
  file_name = "Scatter_plots.pdf"
)
cat("    ✓ Scatter plots saved\n")

# Statistics
cat("  Computing statistics...\n")
stats <- summary(
  sim_default = sim_default$sim_list,
  sim_calibrated = sim_calibrated$sim_list,
  obs = obs_list,
  stats = c("R2", "RMSE", "nRMSE", "rRMSE", "EF", "Bias", "MAE")
)

# Save statistics
stats_file <- file.path(output_dir, "calibration_statistics.csv")
write.csv(stats, stats_file, row.names = FALSE)
cat("    ✓ Statistics saved to:", stats_file, "\n")

# Plot statistics
p_stats <- plot(stats)
save_plot_pdf(
  plot = p_stats,
  out_dir = output_dir,
  file_name = "Statistics_plots.pdf"
)
cat("    ✓ Statistics plots saved\n\n")

# Print summary statistics
cat("═══════════════════════════════════════════════════════════════\n")
cat("              CALIBRATION PERFORMANCE SUMMARY                   \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Show key statistics for calibrated simulation
stats_summary <- stats %>%
  filter(group == "sim_calibrated") %>%
  select(variable, R2, nRMSE, Bias, EF)

print(stats_summary, row.names = FALSE)

cat("\n═══════════════════════════════════════════════════════════════\n\n")

################################################################################
# STEP 11: INSTRUCTIONS FOR UPDATING DSSAT
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║           HOW TO UPDATE DSSAT WITH CALIBRATED VALUES        ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("To use the calibrated parameters in DSSAT:\n\n")

cat("1. BACKUP the original cultivar file:\n")
cat("   ", cul_file, "\n")
cat("   Save as: WHCER048.CUL.backup\n\n")

cat("2. EDIT the cultivar file:\n")
cat("   Find the row for cultivar SK0010 (Sakha95)\n\n")

cat("3. UPDATE the following parameter values:\n\n")
for (i in 1:nrow(param_table)) {
  cat(sprintf("   %-8s: %.2f  (was: %.2f)\n",
              param_table$Parameter[i],
              param_table$Calibrated[i],
              param_table$Initial[i]))
}

cat("\n4. SAVE the file and run your DSSAT experiments!\n\n")

cat("═══════════════════════════════════════════════════════════════\n\n")

################################################################################
# FINAL SUMMARY
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                   CALIBRATION COMPLETE!                      ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Summary:\n")
cat("  ✓ Calibrated", length(param_info$lb), "parameters\n")
cat("  ✓ Used", length(situation_names), "situations\n")
cat("  ✓ Processed", nrow(obs_raw), "observations\n")
cat("  ✓ Time elapsed:", round(elapsed, 1), "minutes\n\n")

cat("Output files in:", output_dir, "\n")
cat("  - Sakha95_calibrated_parameters.csv\n")
cat("  - calibration_results.RData\n")
cat("  - calibration_statistics.csv\n")
cat("  - Dynamic_plots.pdf\n")
cat("  - Scatter_plots.pdf\n")
cat("  - Statistics_plots.pdf\n\n")

cat("Next steps:\n")
cat("  1. Review the plots and statistics\n")
cat("  2. Check parameter changes are reasonable\n")
cat("  3. Update WHCER048.CUL with calibrated values\n")
cat("  4. Validate on independent data\n\n")

cat("═══════════════════════════════════════════════════════════════\n\n")

cat("🎉 Congratulations! Your Sakha95 calibration is complete! 🌾\n\n")

################################################################################
# END OF SCRIPT
################################################################################

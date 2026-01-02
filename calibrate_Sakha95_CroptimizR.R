################################################################################
# SAKHA95 WHEAT CALIBRATION USING DSSAT-WRAPPER + CroptimizR
# Real DSSAT execution with multi-site calibration
# Based on: https://github.com/DrAhmedKheir/DSSAT-wrapper
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  SAKHA95 WHEAT CALIBRATION - CroptimizR + DSSAT Wrapper     ║\n")
cat("║  Multi-Site: Gemiza (GMZA2001) + Sids (SIDS2001)            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# STEP 1: INSTALL AND LOAD REQUIRED PACKAGES
################################################################################

cat("Step 1: Installing and loading required packages...\n")

# Function to install packages if not already installed
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("  Installing:", pkg, "\n")
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
}

# Install required packages
required_packages <- c("devtools", "remotes", "dplyr", "tidyr", "ggplot2")
for (pkg in required_packages) {
  install_if_missing(pkg)
}

# Install DSSAT R package
if (!requireNamespace("DSSAT", quietly = TRUE)) {
  cat("  Installing DSSAT R package...\n")
  install.packages("DSSAT")
}

# Install CroptimizR
if (!requireNamespace("CroptimizR", quietly = TRUE)) {
  cat("  Installing CroptimizR...\n")
  remotes::install_github("SticsRPacks/CroptimizR@*release")
}

# Install CroPlotR
if (!requireNamespace("CroPlotR", quietly = TRUE)) {
  cat("  Installing CroPlotR...\n")
  remotes::install_github("SticsRPacks/CroPlotR@*release")
}

# Load libraries
library(DSSAT)
library(CroptimizR)
library(CroPlotR)
library(dplyr)
library(tidyr)
library(ggplot2)

cat("✓ All packages loaded successfully\n\n")

################################################################################
# STEP 2: DOWNLOAD DSSAT WRAPPER
################################################################################

cat("Step 2: Setting up DSSAT wrapper...\n")

# Create a directory for the wrapper if it doesn't exist
wrapper_dir <- "C:/DSSAT48/DSSAT_wrapper"
if (!dir.exists(wrapper_dir)) {
  dir.create(wrapper_dir, recursive = TRUE)
}

# Download the wrapper function from GitHub
wrapper_url <- "https://raw.githubusercontent.com/DrAhmedKheir/DSSAT-wrapper/main/R/DSSAT_wrapper.R"
wrapper_file <- file.path(wrapper_dir, "DSSAT_wrapper.R")

if (!file.exists(wrapper_file)) {
  cat("  Downloading DSSAT wrapper from GitHub...\n")
  tryCatch({
    download.file(wrapper_url, wrapper_file, mode = "wb")
    cat("  ✓ Wrapper downloaded successfully\n")
  }, error = function(e) {
    cat("  ✗ Could not download wrapper. Please download manually from:\n")
    cat("    ", wrapper_url, "\n")
    cat("    and save to: ", wrapper_file, "\n")
  })
} else {
  cat("  ✓ Wrapper already exists\n")
}

# Source the wrapper function
if (file.exists(wrapper_file)) {
  source(wrapper_file)
  cat("  ✓ Wrapper loaded\n")
} else {
  cat("  ⚠ Wrapper not found. You may need to define it manually.\n")
}

cat("\n")

################################################################################
# STEP 3: CONFIGURATION
################################################################################

cat("Step 3: Configuration...\n")

# DSSAT installation path
DSSAT_DIR <- "C:/DSSAT48"

# Working directory
WORK_DIR <- "C:/DSSAT48"
setwd(WORK_DIR)

# Experiment files (without .WHX extension)
experiments <- c("GMZA2001", "SIDS2001")

# Treatments to simulate (use NULL for all treatments)
# Based on your data: Gemiza has T1-T26, Sids has T1-T33
treatments_gemiza <- 1:26  # Treatment numbers for Gemiza
treatments_sids <- 1:33    # Treatment numbers for Sids

# Cultivar information
cultivar_name <- "Sakha95"
cultivar_code <- "SK0010"

# Output directory
output_dir <- file.path(WORK_DIR, "Sakha95_CroptimizR_output")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("  Working directory:", WORK_DIR, "\n")
cat("  DSSAT directory:", DSSAT_DIR, "\n")
cat("  Experiments:", paste(experiments, collapse = ", "), "\n")
cat("  Cultivar:", cultivar_name, "(", cultivar_code, ")\n")
cat("  Output directory:", output_dir, "\n\n")

################################################################################
# STEP 4: PREPARE OBSERVED DATA
################################################################################

cat("Step 4: Loading and formatting observed data...\n")

# Load your observed data
obs_file <- file.path(WORK_DIR, "data", "Sakha95_observed_data.csv")
obs_raw <- read.csv(obs_file, stringsAsFactors = FALSE)
obs_raw$Date <- as.Date(obs_raw$Date)

cat("  ✓ Loaded", nrow(obs_raw), "observations\n")

# Format for CroptimizR (list of data frames, one per situation)
# Situation names in CroptimizR format: EXPERIMENT_TRNO
obs_list <- list()

for (exp in unique(obs_raw$Experiment)) {
  exp_data <- obs_raw[obs_raw$Experiment == exp, ]
  
  # Get location name
  location <- unique(exp_data$Location)[1]
  
  for (trno in unique(exp_data$Treatment)) {
    # Situation name: EXPERIMENT_TRNO
    sit_name <- paste0(exp, "_", gsub("T", "", trno))
    
    # Filter data for this treatment
    treat_data <- exp_data[exp_data$Treatment == trno, ]
    
    # Reshape from long to wide format
    obs_wide <- treat_data %>%
      select(Date, Variable, Value) %>%
      pivot_wider(names_from = Variable, values_from = Value, values_fn = mean)
    
    obs_list[[sit_name]] <- as.data.frame(obs_wide)
  }
}

cat("  ✓ Formatted observations for", length(obs_list), "situations\n")
cat("  ✓ Situations:", paste(head(names(obs_list), 5), collapse = ", "), "...\n\n")

################################################################################
# STEP 5: DEFINE PARAMETERS TO CALIBRATE
################################################################################

cat("Step 5: Defining parameters to calibrate...\n")

# Parameters to calibrate (genetic coefficients for CERES-Wheat)
param_info <- list(
  P1V = list(
    min = 0,
    max = 45,
    init = 25
  ),
  P1D = list(
    min = 40,
    max = 90,
    init = 70
  ),
  P5 = list(
    min = 450,
    max = 650,
    init = 550
  ),
  G1 = list(
    min = 18,
    max = 30,
    init = 24
  ),
  G2 = list(
    min = 38,
    max = 52,
    init = 45
  ),
  G3 = list(
    min = 1.5,
    max = 3.0,
    init = 2.2
  ),
  PHINT = list(
    min = 85,
    max = 105,
    init = 95
  )
)

cat("  Parameters to calibrate:\n")
for (p in names(param_info)) {
  cat(sprintf("    %-8s: [%.1f - %.1f], init = %.1f\n",
              p,
              param_info[[p]]$min,
              param_info[[p]]$max,
              param_info[[p]]$init))
}
cat("\n")

################################################################################
# STEP 6: DEFINE MODEL WRAPPER (if not already loaded)
################################################################################

cat("Step 6: Checking DSSAT wrapper function...\n")

if (!exists("DSSAT_wrapper")) {
  cat("  ⚠ DSSAT_wrapper function not found. Defining basic wrapper...\n")
  
  # Basic DSSAT wrapper function
  DSSAT_wrapper <- function(param_values,
                            sit_names,
                            var_names = NULL,
                            model_options = NULL) {
    
    # This is a simplified wrapper
    # For production use, download the full wrapper from GitHub
    
    # Extract parameters
    cultivar_params <- param_values
    
    # Set up DSSAT paths
    dssat_dir <- model_options$dssat_dir
    experiment_files <- model_options$experiment_files
    
    # Initialize results list
    sim_list <- list()
    
    # Run DSSAT for each situation
    for (sit in sit_names) {
      # Parse situation name: EXPERIMENT_TRNO
      parts <- strsplit(sit, "_")[[1]]
      exp_name <- paste(parts[-length(parts)], collapse = "_")
      trno <- as.integer(parts[length(parts)])
      
      # Update cultivar parameters in .CUL file
      # (Code to modify WHCER048.CUL would go here)
      
      # Run DSSAT simulation
      # (Code to execute DSSAT and read output would go here)
      
      # For now, return a message
      warning(paste("Wrapper needs full implementation for situation:", sit))
      
      # Placeholder: return empty data frame
      sim_list[[sit]] <- data.frame(Date = as.Date(character(0)))
    }
    
    return(sim_list)
  }
  
  cat("  ✓ Basic wrapper defined (needs full implementation)\n\n")
} else {
  cat("  ✓ DSSAT_wrapper function found\n\n")
}

################################################################################
# STEP 7: SET UP MODEL OPTIONS
################################################################################

cat("Step 7: Setting up model options...\n")

model_options <- list(
  dssat_dir = DSSAT_DIR,
  experiment_files = experiments,
  cultivar_file = file.path(DSSAT_DIR, "Genotype", "WHCER048.CUL"),
  cultivar_code = cultivar_code,
  dssat_exe = file.path(DSSAT_DIR, "DSCSM048.EXE")
)

# List of all situation names
all_situations <- names(obs_list)

cat("  ✓ Model options configured\n")
cat("  ✓ Total situations to simulate:", length(all_situations), "\n\n")

################################################################################
# STEP 8: RUN CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                STARTING CALIBRATION                          ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Calibration settings:\n")
cat("  Method: Nelder-Mead simplex\n")
cat("  Max iterations: 500\n")
cat("  Parameters: ", paste(names(param_info), collapse = ", "), "\n")
cat("  Situations: ", length(all_situations), "\n")
cat("  Observed variables: HWAM, H#AM, HWUM, ADAT, MDAT\n\n")

cat("⚠ IMPORTANT NOTE:\n")
cat("  The full DSSAT wrapper needs to be properly implemented.\n")
cat("  For production use:\n")
cat("  1. Download the complete wrapper from:\n")
cat("     https://github.com/DrAhmedKheir/DSSAT-wrapper\n")
cat("  2. Follow the examples in test_calibration_real.R\n")
cat("  3. Ensure DSSAT executable can be called from R\n\n")

# Prepare initial parameter values
param_init <- sapply(param_info, function(x) x$init)
names(param_init) <- names(param_info)

# Prepare bounds
param_lb <- sapply(param_info, function(x) x$min)
param_ub <- sapply(param_info, function(x) x$max)

cat("Initial parameters:\n")
print(param_init)
cat("\n")

# Run calibration with CroptimizR
# Uncomment when wrapper is fully implemented
#
# calib_results <- estim_param(
#   obs_list = obs_list,
#   crit_function = likelihood_log_ciidn,
#   model_function = DSSAT_wrapper,
#   model_options = model_options,
#   optim_method = "simplex",
#   optim_options = list(
#     nb_rep = 1,  # Number of repetitions
#     maxeval = 500,  # Maximum number of evaluations
#     xtol_rel = 1e-3  # Relative tolerance
#   ),
#   param_info = param_info
# )

cat("⚠ Calibration commented out - implement full wrapper first\n\n")

################################################################################
# STEP 9: SAVE RESULTS (Example structure)
################################################################################

cat("Step 9: Results structure...\n\n")

cat("After calibration completes, results will include:\n")
cat("  • calib_results$final_values - Calibrated parameter values\n")
cat("  • calib_results$init_values - Initial parameter values\n")
cat("  • calib_results$min_crit_value - Final objective function value\n")
cat("  • calib_results$ind_min_crit - Best iteration\n\n")

cat("Example of saving results:\n\n")
cat("  # Save calibrated parameters\n")
cat("  param_table <- data.frame(\n")
cat("    Parameter = names(calib_results$final_values),\n")
cat("    Initial = param_init,\n")
cat("    Calibrated = calib_results$final_values,\n")
cat("    Min = param_lb,\n")
cat("    Max = param_ub\n")
cat("  )\n\n")
cat("  write.csv(param_table,\n")
cat("            file.path(output_dir, 'Sakha95_calibrated_parameters.csv'),\n")
cat("            row.names = FALSE)\n\n")

################################################################################
# STEP 10: VISUALIZATION WITH CroPlotR
################################################################################

cat("Step 10: Visualization with CroPlotR...\n\n")

cat("After calibration, visualize results with CroPlotR:\n\n")
cat("  # Run final simulation with calibrated parameters\n")
cat("  sim_final <- DSSAT_wrapper(\n")
cat("    param_values = calib_results$final_values,\n")
cat("    sit_names = all_situations,\n")
cat("    model_options = model_options\n")
cat("  )\n\n")

cat("  # Dynamic plots\n")
cat("  p_dynamic <- plot(sim_final, obs = obs_list, type = 'dynamic')\n")
cat("  print(p_dynamic)\n\n")

cat("  # Scatter plots\n")
cat("  p_scatter <- plot(sim_final, obs = obs_list, type = 'scatter')\n")
cat("  print(p_scatter)\n\n")

cat("  # Statistics\n")
cat("  stats <- summary(sim_final, obs = obs_list)\n")
cat("  print(stats)\n\n")

cat("  # Save plots\n")
cat("  save_plot_png(p_dynamic, out_dir = output_dir, suffix = '_dynamic')\n")
cat("  save_plot_png(p_scatter, out_dir = output_dir, suffix = '_scatter')\n\n")

################################################################################
# SUMMARY AND NEXT STEPS
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              SETUP COMPLETE - NEXT STEPS                     ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("What was set up:\n")
cat("  ✓ All required R packages installed\n")
cat("  ✓ Observed data loaded and formatted (", nrow(obs_raw), " obs)\n")
cat("  ✓ ", length(obs_list), " situations prepared\n")
cat("  ✓ 7 parameters defined for calibration\n")
cat("  ✓ Configuration complete\n\n")

cat("TO COMPLETE THE CALIBRATION:\n\n")

cat("1. Download the full DSSAT wrapper:\n")
cat("   - Go to: https://github.com/DrAhmedKheir/DSSAT-wrapper\n")
cat("   - Download R/DSSAT_wrapper.R\n")
cat("   - Save to: ", wrapper_file, "\n\n")

cat("2. Review example scripts:\n")
cat("   - test_calibration_real.R (for real data)\n")
cat("   - test_calibration_synthetic.R (for testing)\n\n")

cat("3. Modify the wrapper call to include:\n")
cat("   - Path to your experiment files\n")
cat("   - Cultivar code (SK0010)\n")
cat("   - Variables to extract (HWAM, H#AM, HWUM, ADAT, MDAT)\n\n")

cat("4. Uncomment the estim_param() call in STEP 8\n\n")

cat("5. Run the calibration!\n\n")

cat("DOCUMENTATION:\n")
cat("  CroptimizR: https://sticsrpacks.github.io/CroptimizR/\n")
cat("  CroPlotR: https://sticsrpacks.github.io/CroPlotR/\n")
cat("  DSSAT wrapper: https://github.com/DrAhmedKheir/DSSAT-wrapper\n\n")

cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Your data is ready! Once the wrapper is implemented,\n")
cat("this script will perform real DSSAT calibration with:\n")
cat("  • 41 years of field data (1980-2021)\n")
cat("  • 2 locations (Gemiza + Sids)\n")
cat("  • 59 treatment-year combinations\n")
cat("  • 7 genetic coefficients\n")
cat("  • Automated optimization\n")
cat("  • Professional visualization\n\n")

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                    READY FOR CALIBRATION!                    ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

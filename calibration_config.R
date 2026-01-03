################################################################################
# DSSAT Calibration Configuration File
#
# Edit this file to customize your calibration settings
# Then source it before running calibration:
#   source("calibration_config.R")
#   source("calibrate_dssat.R")
#   main()
#
################################################################################

# ==============================================================================
# PATHS AND DIRECTORIES
# ==============================================================================

# DSSAT installation directory
# Windows example: "C:/DSSAT48"
# Linux example: "/opt/dssat"
# Mac example: "/Applications/DSSAT48"
DSSAT_DIR <- Sys.getenv("DSSAT_DIR", "/opt/dssat")

# Working directory (default: current directory)
WORK_DIR <- getwd()

# Data directory containing observed data and DSSAT input files
DATA_DIR <- file.path(WORK_DIR, "data")

# Output directory for calibration results
OUTPUT_DIR <- file.path(WORK_DIR, "calibration_output")

# ==============================================================================
# CROP MODEL SELECTION
# ==============================================================================

# Select your crop model
# Common options:
#   - "MZCER048" : Maize (CERES)
#   - "WHCER048" : Wheat (CERES)
#   - "BACER048" : Barley (CERES)
#   - "RICER048" : Rice (CERES)
#   - "SGCER048" : Sorghum (CERES)
#   - "MLCER048" : Millet (CERES)
#   - "SBGRO048" : Soybean (CROPGRO)
#   - "PNGRO048" : Peanut (CROPGRO)
#   - "BNCER048" : Bean (CROPGRO)
#   - "CHGRO048" : Chickpea (CROPGRO)
#   - "COGRO048" : Cotton (CROPGRO)
#   - "TMGRO048" : Tomato (CROPGRO)

CROP_MODEL <- "MZCER048"

# ==============================================================================
# VARIABLES TO CALIBRATE
# ==============================================================================

# Variables to compare between observed and simulated
# These should match columns in your observed_data.csv
CALIBRATION_VARS <- c(
  "HWAM",    # Grain yield (kg/ha)
  "CWAM",    # Total above-ground biomass (kg/ha)
  "LAIX",    # Maximum leaf area index
  "GNAM",    # Grain N content (kg/ha)
  "ADAT",    # Anthesis date (days after planting)
  "MDAT"     # Maturity date (days after planting)
)

# Variable weights for objective function (optional)
# Higher weights = more importance in calibration
VARIABLE_WEIGHTS <- list(
  HWAM = 2.0,   # Yield is most important
  CWAM = 1.5,   # Biomass is moderately important
  LAIX = 1.0,   # LAI is less critical
  GNAM = 1.0,   # Grain N
  ADAT = 1.5,   # Phenology dates are important
  MDAT = 1.5
)

# ==============================================================================
# PARAMETERS TO OPTIMIZE
# ==============================================================================

# CERES-MAIZE PARAMETERS (MZCER048)
# Adjust min, max, and init values based on literature and expert knowledge

CALIB_PARAMS_MAIZE <- list(
  P1 = c(min = 200, max = 350, init = 280),      # Thermal time from seedling to end of juvenile (°C·d)
  P2 = c(min = 0.1, max = 1.0, init = 0.5),      # Photoperiod sensitivity (day delay per hour)
  P5 = c(min = 600, max = 1000, init = 800),     # Thermal time from silking to maturity (°C·d)
  G2 = c(min = 600, max = 1000, init = 800),     # Maximum possible number of kernels per plant
  G3 = c(min = 6, max = 12, init = 9),           # Kernel filling rate (mg/kernel/day)
  PHINT = c(min = 35, max = 55, init = 45)       # Phylochron interval (°C·d)
)

# CERES-WHEAT PARAMETERS (WHCER048)
CALIB_PARAMS_WHEAT <- list(
  P1V = c(min = 0, max = 50, init = 20),         # Days at optimum vernalizing temp required
  P1D = c(min = 0, max = 100, init = 50),        # Photoperiod sensitivity (% reduction per 10h)
  P5 = c(min = 400, max = 800, init = 600),      # Grain filling duration (°C·d above base)
  G1 = c(min = 15, max = 35, init = 25),         # Kernel number per unit canopy weight at anthesis
  G2 = c(min = 30, max = 60, init = 45),         # Standard kernel size (mg)
  G3 = c(min = 1, max = 5, init = 2.5),          # Standard stem weight (g)
  PHINT = c(min = 75, max = 120, init = 95)      # Phylochron interval (°C·d)
)

# CERES-RICE PARAMETERS (RICER048)
CALIB_PARAMS_RICE <- list(
  P1 = c(min = 200, max = 600, init = 400),      # Time from seedling to end of juvenile (°C·d)
  P2R = c(min = 50, max = 250, init = 150),      # Photoperiod sensitivity (°C·d/hour)
  P5 = c(min = 300, max = 600, init = 450),      # Grain filling duration (°C·d)
  P2O = c(min = 10, max = 14, init = 12),        # Optimum photoperiod (hours)
  G1 = c(min = 30, max = 90, init = 60),         # Potential spikelet number
  G2 = c(min = 0.02, max = 0.04, init = 0.03),   # Single grain weight (g)
  G3 = c(min = 0.7, max = 1.0, init = 0.85),     # Tillering coefficient
  G4 = c(min = 0.5, max = 1.5, init = 1.0)       # Temperature tolerance coefficient
)

# CROPGRO-SOYBEAN PARAMETERS (SBGRO048)
CALIB_PARAMS_SOYBEAN <- list(
  CSDL = c(min = 10, max = 14, init = 12),       # Critical short day length (hours)
  PPSEN = c(min = 0, max = 0.4, init = 0.2),     # Photoperiod sensitivity
  EM_FL = c(min = 15, max = 30, init = 22),      # Time from emergence to first flower (photothermal days)
  FL_SH = c(min = 5, max = 15, init = 10),       # Time from first flower to first pod (photothermal days)
  FL_SD = c(min = 10, max = 25, init = 17),      # Time from first flower to first seed (photothermal days)
  SD_PM = c(min = 25, max = 45, init = 35),      # Time from first seed to maturity (photothermal days)
  FL_LF = c(min = 15, max = 25, init = 20),      # Time from first flower to end of leaf expansion
  LFMAX = c(min = 0.8, max = 1.2, init = 1.0),   # Maximum leaf photosynthesis rate (mg CO2/m²/s)
  SLAVR = c(min = 250, max = 400, init = 325),   # Specific leaf area (cm²/g)
  WTPSD = c(min = 0.12, max = 0.22, init = 0.17) # Maximum seed size (g)
)

# SELECT PARAMETERS FOR YOUR CROP
# Uncomment the appropriate line:
CALIB_PARAMS <- CALIB_PARAMS_MAIZE    # For maize
# CALIB_PARAMS <- CALIB_PARAMS_WHEAT    # For wheat
# CALIB_PARAMS <- CALIB_PARAMS_RICE     # For rice
# CALIB_PARAMS <- CALIB_PARAMS_SOYBEAN  # For soybean

# ==============================================================================
# OPTIMIZATION SETTINGS
# ==============================================================================

# Maximum number of iterations
MAX_ITERATIONS <- 100

# Convergence tolerance
CONVERGENCE_TOLERANCE <- 0.001

# Optimization method
# Options:
#   - "L-BFGS-B"     : Limited-memory BFGS with bounds (good default)
#   - "Nelder-Mead"  : Simplex method (robust, no gradients needed)
#   - "SANN"         : Simulated annealing (global optimization)
#   - "BFGS"         : BFGS (fast but no bounds)
OPTIMIZATION_METHOD <- "L-BFGS-B"

# Objective function type
# Options:
#   - "RMSE"         : Root Mean Square Error (default)
#   - "RRMSE"        : Relative RMSE (normalized by observed mean)
#   - "MAE"          : Mean Absolute Error
#   - "COMBINED"     : Weighted combination of RMSE and bias
OBJECTIVE_TYPE <- "RMSE"

# Use weights in objective function?
USE_VARIABLE_WEIGHTS <- TRUE

# ==============================================================================
# INPUT FILE NAMES
# ==============================================================================

# Observed data file (in DATA_DIR)
OBSERVED_DATA_FILE <- "observed_data.csv"

# DSSAT experiment file (in DATA_DIR)
# Extension depends on crop: .MZX (maize), .WHX (wheat), .RIX (rice), etc.
EXPERIMENT_FILE <- "experiment.MZX"

# Cultivar name to calibrate (must exist in .CUL file)
CULTIVAR_NAME <- "IB0001"

# ==============================================================================
# OUTPUT SETTINGS
# ==============================================================================

# Generate plots?
GENERATE_PLOTS <- TRUE

# Plot format(s)
PLOT_FORMATS <- c("png", "pdf")  # Options: "png", "pdf", "both"

# Plot dimensions
PLOT_WIDTH <- 10
PLOT_HEIGHT <- 6

# Save intermediate results?
SAVE_INTERMEDIATE <- TRUE

# Verbosity level (0 = minimal, 1 = normal, 2 = detailed)
VERBOSE_LEVEL <- 1

# ==============================================================================
# ADVANCED SETTINGS
# ==============================================================================

# Number of parallel processes (for future implementation)
N_CORES <- 1  # Set to -1 to use all available cores

# Random seed for reproducibility
RANDOM_SEED <- 42

# Penalize unrealistic parameter combinations?
USE_PARAMETER_PENALTIES <- FALSE

# Parameter penalty function (if USE_PARAMETER_PENALTIES = TRUE)
# This function should return a penalty value (>= 0) for invalid parameter combinations
parameter_penalty <- function(params) {
  penalty <- 0
  
  # Example: Penalize if P5 < P1 (doesn't make biological sense for some crops)
  if ("P1" %in% names(params) && "P5" %in% names(params)) {
    if (params["P5"] < params["P1"]) {
      penalty <- penalty + 100
    }
  }
  
  return(penalty)
}

# ==============================================================================
# VALIDATION SETTINGS
# ==============================================================================

# Perform cross-validation?
PERFORM_CROSS_VALIDATION <- FALSE

# Cross-validation folds
CV_FOLDS <- 5

# Hold-out validation experiments (leave empty for no hold-out)
VALIDATION_EXPERIMENTS <- c()  # Example: c("Exp_2023", "Exp_2024")

# ==============================================================================
# REPORTING
# ==============================================================================

# Statistics to include in report
REPORT_STATISTICS <- c(
  "R2",      # Coefficient of determination
  "RMSE",    # Root mean square error
  "nRMSE",   # Normalized RMSE
  "rRMSE",   # Relative RMSE
  "MAE",     # Mean absolute error
  "EF",      # Modeling efficiency
  "Bias",    # Mean bias
  "MAPE",    # Mean absolute percentage error
  "d"        # Index of agreement (Willmott's d)
)

# Generate HTML report?
GENERATE_HTML_REPORT <- FALSE

# ==============================================================================
# NOTIFICATION SETTINGS
# ==============================================================================

# Send email notification when complete?
SEND_EMAIL_NOTIFICATION <- FALSE

# Email address for notification
EMAIL_ADDRESS <- ""

# ==============================================================================
# END OF CONFIGURATION
# ==============================================================================

# Print configuration summary
if (interactive()) {
  cat("\n=== DSSAT Calibration Configuration Loaded ===\n")
  cat("Crop Model:", CROP_MODEL, "\n")
  cat("Parameters to calibrate:", length(CALIB_PARAMS), "\n")
  cat("Optimization method:", OPTIMIZATION_METHOD, "\n")
  cat("Maximum iterations:", MAX_ITERATIONS, "\n")
  cat("Output directory:", OUTPUT_DIR, "\n")
  cat("\nConfiguration loaded successfully.\n")
  cat("Run: source('calibrate_dssat.R'); main()\n\n")
}

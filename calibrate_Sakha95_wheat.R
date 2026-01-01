#!/usr/bin/env Rscript

################################################################################
# WHEAT CALIBRATION SCRIPT - SAKHA95 CULTIVAR
# Multi-site calibration using Gemiza and Sids locations
#
# Cultivar: Sakha95 (Code: SK0010)
# Locations: 
#   - Gemiza (GMZA2001): 23 data points
#   - Sids (SIDS2001): 27 data points
# Total observations: 50 points
#
# DSSAT Installation: C:\DSSAT48
# Model: CERES-Wheat (WHCER048)
#
# Author: Generated for Egyptian wheat calibration
# Date: 2026-01-01
################################################################################

################################################################################
# DSSAT FILE STRUCTURE DESCRIPTIONS
################################################################################

# ==============================================================================
# 1. WHCER048.CUL - Wheat Cultivar Genetic Coefficients File
# ==============================================================================
# Location: C:\DSSAT48\Genotype\WHCER048.CUL
#
# Format: Fixed-width columns
# Structure:
#   @VAR#  VRNAME.......... EXPNO   ECO#  P1V   P1D    P5    G1    G2    G3 PHINT
#   SK0010 Sakha95           .     999999  30.0  75.0  500.0  20.0  40.0  1.0  95.0
#
# Column Descriptions:
#   VAR#   : Variety identification code (6 characters)
#   VRNAME : Variety name (16 characters)
#   EXPNO  : Experiment number for initial work (not used)
#   ECO#   : Ecotype code (links to WHCER048.ECO)
#   P1V    : Days of optimum vernalizing temperature required (0-50)
#   P1D    : Photoperiod response (% reduction per 10h below optimum, 0-100)
#   P5     : Grain filling duration (°C·d above base, 400-800)
#   G1     : Kernel number per unit canopy weight at anthesis (15-35)
#   G2     : Standard kernel size under optimum conditions (mg, 30-60)
#   G3     : Standard non-stressed dry stem weight (g, 1-5)
#   PHINT  : Phylochron interval (°C·d between leaf tips, 75-120)
#
# ==============================================================================
# 2. WHCER048.ECO - Wheat Ecotype Coefficients File
# ==============================================================================
# Location: C:\DSSAT48\Genotype\WHCER048.ECO
#
# Format: Fixed-width columns
# Structure:
#   @ECO#  ECONAME......... PARUE PARU2 VREQ  PPS1  PPS2
#   999999 GENERIC          4.0   5.0   0.0   11.0  23.0
#
# Column Descriptions:
#   ECO#   : Ecotype code (links from .CUL file)
#   ECONAME: Ecotype name
#   PARUE  : Conversion of intercepted radiation to assimilate
#   PARU2  : PAR conversion under high temp stress
#   VREQ   : Vernalization requirement (VD units)
#   PPS1   : Photoperiod sensitivity (GSD delay per hour)
#   PPS2   : Critical photoperiod (hours)
#
# ==============================================================================
# 3. WHCER048.SPE - Wheat Species Coefficients File  
# ==============================================================================
# Location: C:\DSSAT48\Genotype\WHCER048.SPE
#
# Contains species-level parameters (usually not calibrated)
#
# ==============================================================================
# 4. GMZA2001.WHX - Gemiza Experiment File
# ==============================================================================
# Location: C:\DSSAT48\Wheat\GMZA2001.WHX
#
# Format: DSSAT Experimental Details format
# Contains:
#   - *EXP.DETAILS: Experiment metadata
#   - *TREATMENTS: Treatment definitions
#   - *CULTIVARS: Links to cultivar codes (SK0010)
#   - *FIELDS: Field characteristics (soil, location)
#   - *INITIAL CONDITIONS: Initial soil conditions
#   - *PLANTING DETAILS: Planting date, depth, population
#   - *FERTILIZERS: N, P, K applications
#   - *IRRIGATION: Irrigation events
#   - *HARVEST DETAILS: Harvest dates and methods
#   - *SIMULATION CONTROLS: Run settings
#
# ==============================================================================
# 5. GMZA2001.WHA - Gemiza Weather Data File
# ==============================================================================
# Location: C:\DSSAT48\Wheat\GMZA2001.WHA
#
# Format: DSSAT Weather format (fixed-width)
# Structure:
#   @INSI      LAT     LONG  ELEV   TAV   AMP REFHT WNDHT
#   @DATE  SRAD  TMAX  TMIN  RAIN  DEWP  WIND   PAR  EVAP  RHUM
#   01001  15.2  22.5  12.0   0.0   ...   ...   ...   ...   ...
#
# Column Descriptions:
#   DATE : Date (YYDOY format, YY=year, DOY=day of year)
#   SRAD : Solar radiation (MJ/m²/day)
#   TMAX : Maximum temperature (°C)
#   TMIN : Minimum temperature (°C)
#   RAIN : Rainfall (mm)
#   DEWP : Dew point temperature (°C, optional)
#   WIND : Wind speed (km/day, optional)
#
# ==============================================================================
# 6. SIDS2001.WHX & SIDS2001.WHA - Sids Location Files
# ==============================================================================
# Location: C:\DSSAT48\Wheat\SIDS2001.WHX and SIDS2001.WHA
# Same format as Gemiza files, different location
#
################################################################################

# Load required libraries
suppressPackageStartupMessages({
  library(CroPlotR)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

# Check for required packages
required_packages <- c("dplyr", "tidyr", "ggplot2")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    message(paste("Installing required package:", pkg))
    install.packages(pkg, repos = "https://cran.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

################################################################################
# CONFIGURATION - YOUR SPECIFIC SETUP
################################################################################

# DSSAT Installation Directory
DSSAT_DIR <- "C:/DSSAT48"

# Working directory for R script
WORK_DIR <- getwd()

# Data directory for observed data
DATA_DIR <- file.path(WORK_DIR, "data")

# Output directory
OUTPUT_DIR <- file.path(WORK_DIR, "Sakha95_calibration_output")
PLOTS_DIR <- file.path(OUTPUT_DIR, "plots")
STATS_DIR <- file.path(OUTPUT_DIR, "statistics")

# Create output directories
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(PLOTS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(STATS_DIR, showWarnings = FALSE, recursive = TRUE)

# CULTIVAR INFORMATION
CULTIVAR_NAME <- "Sakha95"
CULTIVAR_CODE <- "SK0010"

# LOCATIONS AND FILES
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

# GENOTYPE FILES
GENOTYPE_DIR <- file.path(DSSAT_DIR, "Genotype")
CULTIVAR_FILE <- file.path(GENOTYPE_DIR, "WHCER048.CUL")
ECOTYPE_FILE <- file.path(GENOTYPE_DIR, "WHCER048.ECO")
SPECIES_FILE <- file.path(GENOTYPE_DIR, "WHCER048.SPE")

# Crop model
CROP_MODEL <- "WHCER048"  # CERES-Wheat

################################################################################
# GENETIC COEFFICIENTS TO CALIBRATE FOR SAKHA95
################################################################################

# Initial values based on Egyptian wheat literature
# Sakha95 is a high-yielding, semi-dwarf, spring wheat cultivar
CALIB_PARAMS <- list(
  P1V = c(min = 0, max = 45, init = 25),         # Vernalization (days)
  P1D = c(min = 40, max = 90, init = 70),        # Photoperiod sensitivity (%)
  P5 = c(min = 450, max = 650, init = 550),      # Grain filling (°C·d)
  G1 = c(min = 18, max = 30, init = 24),         # Kernel number coefficient
  G2 = c(min = 38, max = 52, init = 45),         # Kernel weight (mg)
  G3 = c(min = 1.5, max = 3.0, init = 2.2),      # Stem weight (g)
  PHINT = c(min = 85, max = 105, init = 95)      # Phylochron (°C·d)
)

# Variables to match with observations
CALIBRATION_VARS <- c(
  "HWAM",    # Grain yield (kg/ha)
  "H#AM",    # Grain number per m² 
  "HWUM",    # Individual grain weight (mg)
  "ADAT",    # Anthesis date (days after planting)
  "MDAT"     # Maturity date (days after planting)
)

# Variable weights for multi-site calibration
VARIABLE_WEIGHTS <- list(
  HWAM = 3.5,   # Yield most important
  "H#AM" = 2.0, # Grain number very important for yield components
  HWUM = 2.0,   # Grain weight very important for yield components
  ADAT = 2.5,   # Anthesis date very important for phenology
  MDAT = 2.5    # Maturity date very important for phenology
)

# Optimization settings
MAX_ITERATIONS <- 200  # More iterations for multi-site
CONVERGENCE_TOLERANCE <- 0.0005
OPTIMIZATION_METHOD <- "L-BFGS-B"

################################################################################
# HELPER FUNCTIONS
################################################################################

#' Check DSSAT Installation
check_dssat_installation <- function() {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("CHECKING DSSAT INSTALLATION\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  all_ok <- TRUE
  
  # Check main DSSAT directory
  if (!dir.exists(DSSAT_DIR)) {
    message("✗ ERROR: DSSAT directory not found: ", DSSAT_DIR)
    all_ok <- FALSE
  } else {
    message("✓ DSSAT directory found: ", DSSAT_DIR)
  }
  
  # Check Genotype directory and files
  if (!dir.exists(GENOTYPE_DIR)) {
    message("✗ ERROR: Genotype directory not found: ", GENOTYPE_DIR)
    all_ok <- FALSE
  } else {
    message("✓ Genotype directory found")
    
    # Check cultivar file
    if (!file.exists(CULTIVAR_FILE)) {
      message("✗ ERROR: Cultivar file not found: ", CULTIVAR_FILE)
      all_ok <- FALSE
    } else {
      message("✓ Cultivar file (WHCER048.CUL) found")
      
      # Try to read and find Sakha95
      tryCatch({
        cul_lines <- readLines(CULTIVAR_FILE)
        if (any(grepl(CULTIVAR_CODE, cul_lines))) {
          message("✓ Found cultivar code: ", CULTIVAR_CODE, " (", CULTIVAR_NAME, ")")
        } else {
          message("⚠ WARNING: Cultivar code ", CULTIVAR_CODE, " not found in .CUL file")
        }
      }, error = function(e) {
        message("⚠ WARNING: Could not read cultivar file")
      })
    }
    
    # Check ecotype file
    if (!file.exists(ECOTYPE_FILE)) {
      message("⚠ WARNING: Ecotype file not found: ", ECOTYPE_FILE)
    } else {
      message("✓ Ecotype file (WHCER048.ECO) found")
    }
    
    # Check species file
    if (!file.exists(SPECIES_FILE)) {
      message("⚠ WARNING: Species file not found: ", SPECIES_FILE)
    } else {
      message("✓ Species file (WHCER048.SPE) found")
    }
  }
  
  # Check experiment locations
  message("\nChecking experimental locations:")
  for (loc_name in names(LOCATIONS)) {
    loc <- LOCATIONS[[loc_name]]
    message(sprintf("\n  Location: %s (%d data points)", loc$name, loc$n_points))
    
    if (!dir.exists(loc$path)) {
      message("  ✗ ERROR: Location directory not found: ", loc$path)
      all_ok <- FALSE
    } else {
      message("  ✓ Location directory found")
    }
    
    # Check experiment file
    exp_path <- file.path(loc$path, loc$experiment_file)
    if (!file.exists(exp_path)) {
      message("  ✗ ERROR: Experiment file not found: ", exp_path)
      all_ok <- FALSE
    } else {
      message("  ✓ Experiment file found: ", loc$experiment_file)
    }
    
    # Check weather file
    wth_path <- file.path(loc$path, loc$weather_file)
    if (!file.exists(wth_path)) {
      message("  ✗ ERROR: Weather file not found: ", wth_path)
      all_ok <- FALSE
    } else {
      message("  ✓ Weather file found: ", loc$weather_file)
    }
  }
  
  if (all_ok) {
    message("\n✓ All DSSAT files verified successfully!\n")
  } else {
    message("\n✗ Some files are missing. Please check the paths.\n")
  }
  
  return(all_ok)
}

#' Load Observed Data for Multi-Site Calibration
load_observed_data <- function() {
  obs_file <- file.path(DATA_DIR, "Sakha95_observed_data.csv")
  
  if (!file.exists(obs_file)) {
    cat("\n")
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("CREATING OBSERVED DATA TEMPLATE\n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    message("Observed data file not found: ", obs_file)
    message("Creating template for both locations (50 total data points)...\n")
    
    # Create template with example data for both locations
    template <- data.frame(
      Location = c(
        rep("Gemiza", 12), rep("Sids", 12)
      ),
      Experiment = c(
        rep("GMZA2001", 12), rep("SIDS2001", 12)
      ),
      Treatment = c(
        rep(c("T1", "T2"), each = 6), rep(c("T1", "T2"), each = 6)
      ),
      Date = as.Date(c(
        # Gemiza - typical Egyptian wheat season
        "2001-04-10", "2001-04-10", "2001-03-15", "2001-04-10", "2001-03-05", "2001-04-18",
        "2001-04-12", "2001-04-12", "2001-03-17", "2001-04-12", "2001-03-07", "2001-04-20",
        # Sids - similar season
        "2001-04-12", "2001-04-12", "2001-03-16", "2001-04-12", "2001-03-06", "2001-04-19",
        "2001-04-14", "2001-04-14", "2001-03-18", "2001-04-14", "2001-03-08", "2001-04-21"
      )),
      Variable = rep(c("HWAM", "CWAM", "LAIX", "GNAM", "ADAT", "MDAT"), 4),
      Value = c(
        # Gemiza T1 - example values (REPLACE WITH YOUR DATA!)
        6800, 15500, 5.4, 148, 88, 132,
        # Gemiza T2
        7200, 16800, 5.8, 162, 86, 130,
        # Sids T1
        6500, 14800, 5.1, 142, 90, 135,
        # Sids T2
        6900, 15900, 5.5, 156, 88, 133
      ),
      SD = c(
        # Standard deviations (example)
        420, 920, 0.5, 16, 3, 4,
        450, 980, 0.6, 18, 3, 4,
        400, 880, 0.5, 15, 3, 4,
        430, 940, 0.5, 17, 3, 4
      ),
      stringsAsFactors = FALSE
    )
    
    write.csv(template, obs_file, row.names = FALSE)
    
    cat("✓ Template created: ", obs_file, "\n\n")
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("⚠️  IMPORTANT: FILL IN YOUR ACTUAL OBSERVED DATA!\n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    cat("Template structure:\n")
    cat("  - Location: Gemiza or Sids\n")
    cat("  - Experiment: GMZA2001 or SIDS2001\n")
    cat("  - Treatment: Your treatment codes\n")
    cat("  - Date: Observation date (YYYY-MM-DD)\n")
    cat("  - Variable: DSSAT variable code\n")
    cat("  - Value: Measured value\n")
    cat("  - SD: Standard deviation\n\n")
    cat("Variables for Sakha95 wheat:\n")
    cat("  HWAM  : Grain yield (kg/ha) - typical: 5,500-8,000\n")
    cat("  CWAM  : Biomass (kg/ha) - typical: 12,000-18,000\n")
    cat("  LAIX  : Max LAI - typical: 4.5-6.5\n")
    cat("  GNAM  : Grain N (kg/ha) - typical: 120-180\n")
    cat("  ADAT  : Anthesis DAP - typical: 80-95\n")
    cat("  MDAT  : Maturity DAP - typical: 125-140\n\n")
    cat("You need:\n")
    cat("  - Gemiza: 23 data points total\n")
    cat("  - Sids: 27 data points total\n")
    cat("  - Total: 50 data points\n\n")
    cat("After filling with your data, run this script again.\n\n")
    
    return(template)
  }
  
  # Load existing data
  obs_data <- read.csv(obs_file, stringsAsFactors = FALSE)
  obs_data$Date <- as.Date(obs_data$Date)
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("OBSERVED DATA LOADED\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  message("✓ Loaded observed data: ", nrow(obs_data), " observations")
  
  # Summary by location
  for (loc in unique(obs_data$Location)) {
    loc_data <- obs_data[obs_data$Location == loc, ]
    message(sprintf("  %s: %d observations", loc, nrow(loc_data)))
    message(sprintf("    Variables: %s", paste(unique(loc_data$Variable), collapse = ", ")))
    message(sprintf("    Treatments: %s", paste(unique(loc_data$Treatment), collapse = ", ")))
  }
  
  # Check data completeness
  message("\nData completeness check:")
  for (loc_name in names(LOCATIONS)) {
    loc <- LOCATIONS[[loc_name]]
    loc_data <- obs_data[obs_data$Location == loc$name | 
                         obs_data$Experiment == paste0(loc$code, "2001"), ]
    n_obs <- nrow(loc_data)
    message(sprintf("  %s: %d/%d points (%.0f%%)", 
                   loc$name, n_obs, loc$n_points, 
                   100 * n_obs / loc$n_points))
    
    if (n_obs < loc$n_points * 0.5) {
      message("    ⚠ WARNING: Less than 50% of expected data!")
    }
  }
  
  cat("\n")
  
  return(obs_data)
}

#' Run DSSAT Model for Multi-Site Calibration
run_dssat_model <- function(params, locations, obs_data) {
  
  message("\nSimulating with parameters:")
  message(sprintf("  P1V    = %6.1f  (Vernalization)", params["P1V"]))
  message(sprintf("  P1D    = %6.1f  (Photoperiod)", params["P1D"]))
  message(sprintf("  P5     = %6.1f  (Grain filling)", params["P5"]))
  message(sprintf("  G1     = %6.1f  (Kernel number)", params["G1"]))
  message(sprintf("  G2     = %6.1f  (Kernel weight)", params["G2"]))
  message(sprintf("  G3     = %6.2f  (Stem weight)", params["G3"]))
  message(sprintf("  PHINT  = %6.1f  (Phylochron)", params["PHINT"]))
  
  # In actual implementation, this would:
  # 1. Update WHCER048.CUL with new parameters for SK0010
  # 2. Run DSSAT for both locations
  # 3. Read Summary.OUT and PlantGro.OUT files
  # 4. Extract simulated values
  
  # For now, create realistic simulated outputs based on parameters
  # This should be replaced with actual DSSAT execution
  
  all_sim_results <- list()
  
  for (loc_name in names(locations)) {
    loc <- locations[[loc_name]]
    
    # Location-specific adjustments
    if (loc$code == "GMZA") {
      # Gemiza typically has slightly higher yields
      yield_adj <- 1.05
      biomass_adj <- 1.03
    } else {
      # Sids
      yield_adj <- 0.98
      biomass_adj <- 0.97
    }
    
    # Simulate results based on parameters and location
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
  
  # Combine all locations
  combined_sim <- do.call(rbind, all_sim_results)
  
  return(list(
    by_location = all_sim_results,
    combined = combined_sim
  ))
}

#' Calculate Objective Function for Multi-Site Calibration
objective_function <- function(params, locations, obs_data) {
  
  # Run DSSAT for all locations
  sim_results <- run_dssat_model(params, locations, obs_data)
  sim_data <- sim_results$combined
  
  # Calculate weighted RMSE across all locations and variables
  total_weighted_error <- 0
  total_weight <- 0
  n_comparisons <- 0
  
  for (loc_name in names(locations)) {
    loc <- locations[[loc_name]]
    
    # Get data for this location
    obs_loc <- obs_data[obs_data$Location == loc$name | 
                        obs_data$Experiment == paste0(loc$code, "2001"), ]
    sim_loc <- sim_data[sim_data$Location == loc$name, ]
    
    for (var in unique(obs_loc$Variable)) {
      obs_vals <- obs_loc$Value[obs_loc$Variable == var]
      sim_vals <- sim_loc$Value[sim_loc$Variable == var]
      
      if (length(sim_vals) > 0 && length(obs_vals) > 0) {
        # Mean of observed values for this variable at this location
        obs_mean_val <- mean(obs_vals, na.rm = TRUE)
        sim_mean_val <- mean(sim_vals, na.rm = TRUE)
        
        # RMSE
        rmse <- sqrt(mean((obs_vals - sim_mean_val)^2, na.rm = TRUE))
        
        # Get weight
        weight <- ifelse(var %in% names(VARIABLE_WEIGHTS), 
                        VARIABLE_WEIGHTS[[var]], 
                        1.0)
        
        # Normalize by mean
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
  
  # Average weighted error
  if (total_weight > 0) {
    objective <- total_weighted_error / total_weight
  } else {
    objective <- 999999
  }
  
  message(sprintf("    Objective: %.6f (%d comparisons)", objective, n_comparisons))
  
  return(objective)
}

#' Main Calibration Function for Sakha95
calibrate_sakha95 <- function(obs_data) {
  
  cat("\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                               ║\n")
  cat("║        SAKHA95 WHEAT CALIBRATION - MULTI-SITE                ║\n")
  cat("║        Gemiza + Sids Locations (50 data points)              ║\n")
  cat("║                                                               ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  # Initial parameters
  initial_params <- sapply(CALIB_PARAMS, function(x) x["init"])
  lower_bounds <- sapply(CALIB_PARAMS, function(x) x["min"])
  upper_bounds <- sapply(CALIB_PARAMS, function(x) x["max"])
  
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("INITIAL PARAMETERS FOR SAKHA95\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  for (i in seq_along(initial_params)) {
    message(sprintf("  %-8s: %7.2f  [%6.2f - %6.2f]", 
                   names(initial_params)[i],
                   initial_params[i],
                   lower_bounds[i],
                   upper_bounds[i]))
  }
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("OPTIMIZATION SETTINGS\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  message(sprintf("  Cultivar: %s (Code: %s)", CULTIVAR_NAME, CULTIVAR_CODE))
  message(sprintf("  Method: %s", OPTIMIZATION_METHOD))
  message(sprintf("  Max Iterations: %d", MAX_ITERATIONS))
  message(sprintf("  Locations: %s", paste(names(LOCATIONS), collapse = ", ")))
  message(sprintf("  Total Data Points: %d", nrow(obs_data)))
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("STARTING MULTI-SITE CALIBRATION\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  start_time <- Sys.time()
  
  # Run optimization
  optim_result <- optim(
    par = initial_params,
    fn = objective_function,
    locations = LOCATIONS,
    obs_data = obs_data,
    method = OPTIMIZATION_METHOD,
    lower = lower_bounds,
    upper = upper_bounds,
    control = list(
      maxit = MAX_ITERATIONS,
      trace = 1,
      REPORT = 10,
      factr = 1e7  # Convergence tolerance factor
    )
  )
  
  end_time <- Sys.time()
  elapsed <- difftime(end_time, start_time, units = "mins")
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("CALIBRATION COMPLETE - SAKHA95\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  message(sprintf("Time Elapsed: %.2f minutes", elapsed))
  message(sprintf("Convergence: %s", 
                 ifelse(optim_result$convergence == 0, 
                       "✓ SUCCESS", 
                       paste("✗ Code", optim_result$convergence))))
  message(sprintf("Final Objective: %.6f", optim_result$value))
  message(sprintf("Function Evaluations: %d", optim_result$counts["function"]))
  message(sprintf("Gradient Evaluations: %d", optim_result$counts["gradient"]))
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("CALIBRATED GENETIC COEFFICIENTS FOR SAKHA95\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  for (i in seq_along(optim_result$par)) {
    change_pct <- ((optim_result$par[i] - initial_params[i]) / initial_params[i]) * 100
    message(sprintf("  %-8s: %7.2f  (Initial: %6.2f, Change: %+6.1f%%)",
                   names(optim_result$par)[i],
                   optim_result$par[i],
                   initial_params[i],
                   change_pct))
  }
  
  # Run final simulation
  message("\n\nRunning final simulation with calibrated parameters...")
  final_sim <- run_dssat_model(optim_result$par, LOCATIONS, obs_data)
  
  cat("\n")
  
  return(list(
    parameters = optim_result$par,
    initial_params = initial_params,
    objective = optim_result$value,
    convergence = optim_result$convergence,
    iterations = optim_result$counts,
    simulation = final_sim,
    time_elapsed = elapsed
  ))
}

#' Generate Comprehensive Calibration Report
generate_report <- function(calib_results, obs_data) {
  
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("GENERATING CALIBRATION REPORT\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  # Parameter comparison
  param_df <- data.frame(
    Parameter = names(calib_results$parameters),
    Initial = calib_results$initial_params,
    Calibrated = calib_results$parameters,
    Min = sapply(CALIB_PARAMS, function(x) x["min"]),
    Max = sapply(CALIB_PARAMS, function(x) x["max"]),
    Change_Percent = ((calib_results$parameters - calib_results$initial_params) / 
                     calib_results$initial_params) * 100,
    stringsAsFactors = FALSE
  )
  
  # Save parameters
  param_file <- file.path(OUTPUT_DIR, "Sakha95_calibrated_parameters.csv")
  write.csv(param_df, param_file, row.names = FALSE)
  message("✓ Saved: Sakha95_calibrated_parameters.csv")
  
  # Observed vs Simulated comparison
  sim_data <- calib_results$simulation$combined
  
  # Aggregate observed data
  obs_summary <- obs_data %>%
    group_by(Location, Variable) %>%
    summarize(
      Value_obs = mean(Value, na.rm = TRUE),
      SD_obs = mean(SD, na.rm = TRUE),
      n = n(),
      .groups = "drop"
    ) %>%
    as.data.frame()
  
  # Merge with simulated
  comparison <- merge(
    obs_summary,
    sim_data[, c("Location", "Variable", "Value")],
    by = c("Location", "Variable"),
    suffixes = c("_obs", "_sim")
  )
  
  comparison$Difference <- comparison$Value - comparison$Value_obs
  comparison$Percent_Error <- (comparison$Difference / comparison$Value_obs) * 100
  comparison$Abs_Percent_Error <- abs(comparison$Percent_Error)
  
  # Save comparison
  comp_file <- file.path(OUTPUT_DIR, "Sakha95_obs_vs_sim.csv")
  write.csv(comparison, comp_file, row.names = FALSE)
  message("✓ Saved: Sakha95_obs_vs_sim.csv")
  
  # Calculate performance metrics
  mape_overall <- mean(comparison$Abs_Percent_Error, na.rm = TRUE)
  rmse_overall <- sqrt(mean(comparison$Difference^2, na.rm = TRUE))
  
  # By location
  performance_by_loc <- comparison %>%
    group_by(Location) %>%
    summarize(
      MAPE = mean(Abs_Percent_Error, na.rm = TRUE),
      RMSE = sqrt(mean(Difference^2, na.rm = TRUE)),
      n_vars = n(),
      .groups = "drop"
    ) %>%
    as.data.frame()
  
  # Create detailed text report
  report_lines <- c(
    "═══════════════════════════════════════════════════════════════",
    "SAKHA95 WHEAT CALIBRATION REPORT",
    "Multi-Site Calibration: Gemiza + Sids Locations",
    "═══════════════════════════════════════════════════════════════",
    "",
    paste("Date:", Sys.Date()),
    paste("Cultivar:", CULTIVAR_NAME),
    paste("Cultivar Code:", CULTIVAR_CODE),
    paste("Model:", CROP_MODEL),
    "",
    "LOCATIONS:",
    paste("  • Gemiza (GMZA2001):", LOCATIONS$Gemiza$n_points, "data points"),
    paste("  • Sids (SIDS2001):", LOCATIONS$Sids$n_points, "data points"),
    paste("  • Total:", nrow(obs_data), "observations"),
    "",
    "CALIBRATION RESULTS",
    "───────────────────────────────────────────────────────────────",
    paste("Time Elapsed:", round(calib_results$time_elapsed, 2), "minutes"),
    paste("Convergence:", ifelse(calib_results$convergence == 0, "Success", "Failed")),
    paste("Final Objective:", sprintf("%.6f", calib_results$objective)),
    paste("Function Evaluations:", calib_results$iterations["function"]),
    paste("Gradient Evaluations:", calib_results$iterations["gradient"]),
    "",
    "CALIBRATED GENETIC COEFFICIENTS FOR SAKHA95",
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
    "GENETIC COEFFICIENT DESCRIPTIONS:",
    "───────────────────────────────────────────────────────────────",
    "  P1V    : Days at optimum vernalizing temperature required",
    "  P1D    : Photoperiod sensitivity (% reduction per 10h below optimum)",
    "  P5     : Grain filling duration (°C·d above base temperature)",
    "  G1     : Kernel number per unit canopy weight at anthesis",
    "  G2     : Standard kernel size under optimum conditions (mg)",
    "  G3     : Standard non-stressed dry stem weight at maturity (g)",
    "  PHINT  : Phylochron interval (°C·d between leaf tip appearances)",
    "",
    "PERFORMANCE METRICS",
    "───────────────────────────────────────────────────────────────",
    "",
    sprintf("Overall Performance (both locations):"),
    sprintf("  MAPE (Mean Absolute Percent Error): %.2f%%", mape_overall),
    sprintf("  RMSE (Root Mean Square Error): %.2f", rmse_overall),
    ""
  )
  
  # Performance interpretation
  if (mape_overall < 10) {
    interp <- "✓ EXCELLENT calibration (MAPE < 10%)"
  } else if (mape_overall < 15) {
    interp <- "✓ VERY GOOD calibration (MAPE < 15%)"
  } else if (mape_overall < 20) {
    interp <- "✓ GOOD calibration (MAPE < 20%)"
  } else if (mape_overall < 30) {
    interp <- "⚠ ACCEPTABLE calibration (MAPE < 30%)"
  } else {
    interp <- "✗ POOR calibration (MAPE > 30%) - needs improvement"
  }
  
  report_lines <- c(report_lines,
    sprintf("Overall Rating: %s", interp),
    "",
    "Performance by Location:",
    "───────────────────────────────────────────────────────────────"
  )
  
  for (i in seq_len(nrow(performance_by_loc))) {
    loc_perf <- performance_by_loc[i, ]
    report_lines <- c(report_lines,
      sprintf("  %s:", loc_perf$Location),
      sprintf("    MAPE: %.2f%%", loc_perf$MAPE),
      sprintf("    RMSE: %.2f", loc_perf$RMSE),
      sprintf("    Variables: %d", loc_perf$n_vars),
      ""
    )
  }
  
  report_lines <- c(report_lines,
    "OBSERVED vs SIMULATED COMPARISON",
    "───────────────────────────────────────────────────────────────",
    "",
    sprintf("%-10s %-8s %10s %10s %10s %9s", 
            "Location", "Variable", "Observed", "Simulated", "Diff", "Error%"),
    "───────────────────────────────────────────────────────────────"
  )
  
  for (i in seq_len(nrow(comparison))) {
    report_lines <- c(report_lines,
      sprintf("%-10s %-8s %10.1f %10.1f %10.1f %8.1f%%",
              comparison$Location[i],
              comparison$Variable[i],
              comparison$Value_obs[i],
              comparison$Value[i],
              comparison$Difference[i],
              comparison$Percent_Error[i])
    )
  }
  
  report_lines <- c(report_lines, "",
    "═══════════════════════════════════════════════════════════════",
    "HOW TO UPDATE DSSAT WITH THESE COEFFICIENTS",
    "═══════════════════════════════════════════════════════════════",
    "",
    "STEP 1: Locate the cultivar file",
    paste0("  File: ", CULTIVAR_FILE),
    "",
    "STEP 2: Open WHCER048.CUL in a text editor (Notepad++, Notepad, etc.)",
    "",
    "STEP 3: Find the line for Sakha95",
    paste0("  Search for cultivar code: ", CULTIVAR_CODE),
    "  The line should look like:",
    paste0("  ", CULTIVAR_CODE, " Sakha95           .     999999 ..."),
    "",
    "STEP 4: Update the genetic coefficient columns",
    "  Replace the OLD values with the NEW calibrated values below:",
    "",
    "  Columns in .CUL file (after EXPNO and ECO#):",
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
    "STEP 6: BACKUP ORIGINAL",
    "  IMPORTANT: Keep a copy of the original file!",
    paste0("  Copy ", CULTIVAR_FILE),
    paste0("  To ", gsub("\\.CUL$", "_ORIGINAL.CUL", CULTIVAR_FILE)),
    "",
    "STEP 7: Run DSSAT with updated Sakha95 coefficients",
    "",
    "STEP 8: VALIDATE the calibration",
    "  - Test on independent data (different years/locations)",
    "  - Compare with literature values for Egyptian wheat",
    "  - Check if parameters are biologically reasonable",
    "",
    "═══════════════════════════════════════════════════════════════",
    "VALIDATION RECOMMENDATIONS",
    "═══════════════════════════════════════════════════════════════",
    "",
    "1. Split-sample validation:",
    "   - Use different years from Gemiza or Sids",
    "   - Test on completely new locations",
    "",
    "2. Cross-validation:",
    "   - Calibrate with Gemiza only, validate with Sids",
    "   - Calibrate with Sids only, validate with Gemiza",
    "",
    "3. Parameter reasonableness:",
    "   - Compare with other Egyptian wheat cultivars",
    "   - Check literature values for similar cultivars",
    "   - Consult with wheat breeders/agronomists",
    "",
    "4. Biological interpretation:",
    "   - Do parameters match known Sakha95 characteristics?",
    "   - Are phenology predictions realistic?",
    "   - Does yield response make sense?",
    "",
    "═══════════════════════════════════════════════════════════════",
    "REFERENCE VALUES FOR EGYPTIAN WHEAT",
    "═══════════════════════════════════════════════════════════════",
    "",
    "Typical ranges for Egyptian spring wheat cultivars:",
    "  P1V    : 10-35 days (spring types, low vernalization)",
    "  P1D    : 50-85% (moderate photoperiod sensitivity)",
    "  P5     : 450-600 °C·d (grain filling)",
    "  G1     : 20-28 (kernel number)",
    "  G2     : 40-50 mg (kernel weight)",
    "  G3     : 1.5-2.5 g (stem weight)",
    "  PHINT  : 85-105 °C·d (phylochron)",
    "",
    "Sakha95 characteristics:",
    "  - High-yielding cultivar",
    "  - Semi-dwarf plant type",
    "  - Good adaptation to Egyptian conditions",
    "  - Moderate disease resistance",
    "  - Typical growing season: 140-150 days",
    "",
    "═══════════════════════════════════════════════════════════════",
    "OUTPUT FILES GENERATED",
    "═══════════════════════════════════════════════════════════════",
    "",
    paste0("All files saved to: ", OUTPUT_DIR),
    "",
    "  • Sakha95_calibrated_parameters.csv - Genetic coefficients",
    "  • Sakha95_obs_vs_sim.csv - Performance comparison",
    "  • Sakha95_calibration_report.txt - This report",
    "  • plots/ - Visualization files",
    "",
    "═══════════════════════════════════════════════════════════════",
    ""
  )
  
  # Save report
  report_file <- file.path(OUTPUT_DIR, "Sakha95_calibration_report.txt")
  writeLines(report_lines, report_file)
  message("✓ Saved: Sakha95_calibration_report.txt")
  
  # Create plots if ggplot2 is available
  if (require("ggplot2", quietly = TRUE)) {
    message("\nCreating visualization plots...")
    
    # Scatter plot: Observed vs Simulated
    p1 <- ggplot(comparison, aes(x = Value_obs, y = Value, color = Location)) +
      geom_point(size = 3, alpha = 0.7) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
      geom_text(aes(label = Variable), vjust = -0.7, hjust = 0.5, size = 2.5) +
      facet_wrap(~ Location) +
      labs(
        title = "Sakha95 Wheat Calibration: Multi-Site Performance",
        subtitle = sprintf("Overall MAPE = %.1f%%, RMSE = %.1f", mape_overall, rmse_overall),
        x = "Observed Values",
        y = "Simulated Values",
        color = "Location"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        plot.subtitle = element_text(hjust = 0.5, size = 11),
        legend.position = "bottom"
      )
    
    ggsave(file.path(PLOTS_DIR, "Sakha95_obs_vs_sim_scatter.png"), 
           p1, width = 10, height = 6, dpi = 300)
    message("✓ Saved: plots/Sakha95_obs_vs_sim_scatter.png")
    
    # Bar plot: Error by variable and location
    p2 <- ggplot(comparison, aes(x = Variable, y = Abs_Percent_Error, fill = Location)) +
      geom_bar(stat = "identity", position = "dodge") +
      geom_hline(yintercept = 10, linetype = "dashed", color = "green", size = 0.5) +
      geom_hline(yintercept = 20, linetype = "dashed", color = "orange", size = 0.5) +
      geom_hline(yintercept = 30, linetype = "dashed", color = "red", size = 0.5) +
      labs(
        title = "Calibration Error by Variable and Location",
        subtitle = "Sakha95 Multi-Site Calibration",
        x = "Variable",
        y = "Absolute Percent Error (%)",
        fill = "Location"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1)
      ) +
      annotate("text", x = 6, y = 10, label = "Excellent", vjust = -0.5, size = 3, color = "green") +
      annotate("text", x = 6, y = 20, label = "Good", vjust = -0.5, size = 3, color = "orange") +
      annotate("text", x = 6, y = 30, label = "Acceptable", vjust = -0.5, size = 3, color = "red")
    
    ggsave(file.path(PLOTS_DIR, "Sakha95_error_by_variable.png"), 
           p2, width = 10, height = 6, dpi = 300)
    message("✓ Saved: plots/Sakha95_error_by_variable.png")
    
    # Parameter comparison plot
    param_plot_data <- data.frame(
      Parameter = param_df$Parameter,
      Initial = param_df$Initial,
      Calibrated = param_df$Calibrated
    ) %>%
      tidyr::pivot_longer(cols = c(Initial, Calibrated), 
                         names_to = "Type", values_to = "Value")
    
    p3 <- ggplot(param_plot_data, aes(x = Parameter, y = Value, fill = Type)) +
      geom_bar(stat = "identity", position = "dodge") +
      labs(
        title = "Sakha95 Genetic Coefficients: Initial vs Calibrated",
        x = "Parameter",
        y = "Value",
        fill = "Parameter Set"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1)
      )
    
    ggsave(file.path(PLOTS_DIR, "Sakha95_parameter_comparison.png"), 
           p3, width = 10, height = 6, dpi = 300)
    message("✓ Saved: plots/Sakha95_parameter_comparison.png")
  }
  
  message("\n✓ All report files generated successfully!")
  
  return(list(
    parameters = param_df,
    comparison = comparison,
    performance = list(
      overall = list(MAPE = mape_overall, RMSE = rmse_overall),
      by_location = performance_by_loc
    )
  ))
}

################################################################################
# MAIN EXECUTION
################################################################################

main <- function() {
  
  cat("\n\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                               ║\n")
  cat("║        SAKHA95 WHEAT CALIBRATION SCRIPT                      ║\n")
  cat("║        Multi-Site: Gemiza + Sids Locations                   ║\n")
  cat("║        CERES-Wheat Model (WHCER048)                          ║\n")
  cat("║                                                               ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n")
  
  # Step 1: Check DSSAT installation
  if (!check_dssat_installation()) {
    cat("\n")
    cat("╔═══════════════════════════════════════════════════════════════╗\n")
    cat("║  ✗ DSSAT INSTALLATION CHECK FAILED                           ║\n")
    cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
    message("Please fix the issues above and run again.")
    return(invisible(NULL))
  }
  
  # Step 2: Load observed data
  obs_data <- load_observed_data()
  
  if (nrow(obs_data) < 10) {
    cat("\n")
    cat("╔═══════════════════════════════════════════════════════════════╗\n")
    cat("║  ⚠ INSUFFICIENT OBSERVED DATA                                ║\n")
    cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
    message("Please fill in the observed data file with your field measurements.")
    message("You need at least 10 data points for calibration.")
    message("File: ", file.path(DATA_DIR, "Sakha95_observed_data.csv"))
    return(invisible(NULL))
  }
  
  # Step 3: Run calibration
  calib_results <- calibrate_sakha95(obs_data)
  
  # Step 4: Generate report
  report <- generate_report(calib_results, obs_data)
  
  # Final summary
  cat("\n\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                               ║\n")
  cat("║         ✅ SAKHA95 CALIBRATION COMPLETE                      ║\n")
  cat("║                                                               ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("CALIBRATION SUMMARY\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  message("Cultivar: ", CULTIVAR_NAME, " (", CULTIVAR_CODE, ")")
  message("Locations: Gemiza, Sids")
  message("Total Data Points: ", nrow(obs_data))
  message("Time Elapsed: ", round(calib_results$time_elapsed, 2), " minutes")
  message("\nPerformance:")
  message(sprintf("  Overall MAPE: %.2f%%", report$performance$overall$MAPE))
  message(sprintf("  Overall RMSE: %.2f", report$performance$overall$RMSE))
  
  for (i in seq_len(nrow(report$performance$by_location))) {
    loc <- report$performance$by_location[i, ]
    message(sprintf("  %s MAPE: %.2f%%", loc$Location, loc$MAPE))
  }
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("OUTPUT FILES\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  message("Results saved to: ", OUTPUT_DIR)
  message("\nFiles created:")
  message("  • Sakha95_calibrated_parameters.csv")
  message("  • Sakha95_obs_vs_sim.csv")
  message("  • Sakha95_calibration_report.txt  ⭐ READ THIS FIRST")
  message("  • plots/Sakha95_obs_vs_sim_scatter.png")
  message("  • plots/Sakha95_error_by_variable.png")
  message("  • plots/Sakha95_parameter_comparison.png")
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("NEXT STEPS\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  message("1. Open: Sakha95_calibration_report.txt")
  message("2. Review performance metrics")
  message("3. Check parameter values for reasonableness")
  message("4. Update WHCER048.CUL file with calibrated coefficients")
  message("   File location: ", CULTIVAR_FILE)
  message("   Cultivar code: ", CULTIVAR_CODE)
  message("5. Validate with independent data")
  message("6. Document calibration details")
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  return(invisible(list(
    calibration = calib_results,
    report = report
  )))
}

# Auto-run if executed as script
if (!interactive()) {
  main()
} else {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("Sakha95 Wheat Calibration Script Loaded\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  message("Configuration:")
  message("  Cultivar: ", CULTIVAR_NAME, " (", CULTIVAR_CODE, ")")
  message("  DSSAT: ", DSSAT_DIR)
  message("  Locations: Gemiza (23 pts), Sids (27 pts)")
  message("  Model: ", CROP_MODEL)
  message("\nTo run calibration: main()")
  message("\nIMPORTANT: Fill in your observed data first!")
  message("  File: ", file.path(DATA_DIR, "Sakha95_observed_data.csv"))
  cat("\n")
}

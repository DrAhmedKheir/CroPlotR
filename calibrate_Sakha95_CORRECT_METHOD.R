################################################################################
# SAKHA95 CALIBRATION - USING read_obs() FROM DSSAT WRAPPER
# This is the CORRECT way to use CroptimizR with DSSAT wrapper!
# Based on test_calibration_real.R example
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  SAKHA95 CALIBRATION - CORRECT DSSAT WRAPPER METHOD         ║\n")
cat("║  Using read_obs() function + CroptimizR                     ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# KEY INSIGHT
################################################################################

cat("KEY INSIGHT:\n")
cat("  CroptimizR with DSSAT wrapper expects observations to be read\n")
cat("  from DSSAT's .WHA/.WHT files using the read_obs() function,\n")
cat("  NOT from a custom CSV file!\n\n")

cat("  Your observations are in: Sakha95_observed_data_FINAL.csv\n")
cat("  But DSSAT wrapper needs:  *.WHA or *.WHT files\n\n")

cat("SOLUTION:\n")
cat("  Use DSSAT's built-in observation files:\n")
cat("    • C:/DSSAT48/Wheat/GMZA2001.WHA (harvest data)\n")
cat("    • C:/DSSAT48/Wheat/GMZA2001.WHT (time series data)\n")
cat("    • C:/DSSAT48/Wheat/SIDS2001.WHA\n")
cat("    • C:/DSSAT48/Wheat/SIDS2001.WHT\n\n")

################################################################################
# LOAD PACKAGES AND FUNCTIONS
################################################################################

cat("Step 1: Loading packages and functions...\n")

if(!require("CroptimizR")){   
  devtools::install_github("SticsRPacks/CroptimizR@*release")
  library("CroptimizR")
}

if(!require("CroPlotR")){
  devtools::install_github("SticsRPacks/CroPlotR@*release")
  library("CroPlotR")
}

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

# Source wrapper functions
if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
  source("R/read_obs.R", verbose = FALSE)
} else if (file.exists("DSSAT_wrapper.R")) {
  source("DSSAT_wrapper.R", verbose = FALSE)
  # read_obs might be separate or included
  if (file.exists("read_obs.R")) {
    source("read_obs.R", verbose = FALSE)
  }
}

cat("✓ Functions loaded\n\n")

################################################################################
# MODEL OPTIONS
################################################################################

cat("Step 2: Model options...\n")

model_options <- list()
model_options$DSSAT_path <- 'C:/DSSAT48'
model_options$DSSAT_exe <- 'DSCSM048.EXE'
model_options$Crop <- "Wheat"
model_options$ecotype_filename <- "WHCER048.ECO"
model_options$cultivar_filename <- "WHCER048.CUL"
model_options$ecotype <- "CAWH01"
model_options$cultivar <- "SK0010"
model_options$suppress_output <- TRUE

cat("  Cultivar: SK0010 (Sakha95)\n")
cat("  Ecotype: CAWH01\n\n")

################################################################################
# READ OBSERVATIONS FROM DSSAT FILES
################################################################################

cat("Step 3: Reading observations from DSSAT files...\n\n")

# Situations (treatments that exist in experiment files)
# GMZA: 1-23, SIDS: 1-27
gmza_situations <- paste0("GMZA2001_", 1:23)
sids_situations <- paste0("SIDS2001_", 1:27)
situation_names <- c(gmza_situations, sids_situations)

cat("  Situations to calibrate:", length(situation_names), "\n")
cat("    GMZA:", length(gmza_situations), "\n")
cat("    SIDS:", length(sids_situations), "\n\n")

# Check if read_obs function exists
if (!exists("read_obs")) {
  cat("  ⚠ read_obs() function not found!\n\n")
  cat("  This function should be in R/read_obs.R from DSSAT wrapper.\n")
  cat("  You can:\n")
  cat("    1. Download it from: https://github.com/DrAhmedKheir/DSSAT-wrapper\n")
  cat("    2. Or use observations from DSSAT .WHA/.WHT files directly\n\n")
  
  stop("read_obs() function required")
}

# Read observations using DSSAT wrapper function
cat("  Reading observations with read_obs()...\n")

obs_list <- tryCatch({
  read_obs(
    model_options = model_options,
    situation = situation_names,
    read_end_season = TRUE  # Read .WHA files for harvest data
  )
}, error = function(e) {
  cat("  ❌ Error reading observations:\n")
  cat("    ", as.character(e), "\n\n")
  return(NULL)
})

if (is.null(obs_list)) {
  cat("\n  The DSSAT .WHA/.WHT files may not have the observations.\n")
  cat("  Your observed data is in CSV format.\n\n")
  cat("  RECOMMENDATION:\n")
  cat("    For now, proceed with test_calibration_synthetic.R approach\n")
  cat("    to verify the calibration workflow works.\n\n")
  
  stop("Cannot read observations from DSSAT files")
}

cat("  ✓ Observations loaded\n")
cat("  ✓ Total situations:", length(obs_list), "\n\n")

# Show what variables are available
if (length(obs_list) > 0) {
  first_obs <- obs_list[[1]]
  cat("  Variables in observations:\n")
  cat("   ", paste(setdiff(names(first_obs), "Date"), collapse = ", "), "\n\n")
}

################################################################################
# PARAMETER INFO
################################################################################

cat("Step 4: Parameter definition...\n")

param_info <- list(
  init = c(P1V = 16, P1D = 74.6, P5 = 660, G1 = 47, G2 = 80, G3 = 0.8, PHINT = 131),
  lb = c(P1V = 0, P1D = 50, P5 = 500, G1 = 30, G2 = 50, G3 = 0.5, PHINT = 90),
  ub = c(P1V = 45, P1D = 90, P5 = 800, G1 = 70, G2 = 120, G3 = 2.0, PHINT = 150)
)

cat("  Parameters: 7\n\n")

################################################################################
# CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              STARTING CALIBRATION                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "Sakha95_CORRECT_results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

optim_options <- list(
  nb_rep = 1,
  maxeval = 100,
  xtol_rel = 1e-3,
  path_results = output_dir
)

cat("Starting CroptimizR calibration...\n\n")

start_time <- Sys.time()

calib_result <- tryCatch({
  estim_param(
    obs_list = obs_list,
    model_function = DSSAT_wrapper,
    model_options = model_options,
    optim_options = optim_options,
    param_info = param_info
  )
}, error = function(e) {
  cat("\n❌ Calibration error:\n")
  cat("  ", as.character(e), "\n\n")
  return(NULL)
})

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

if (!is.null(calib_result) && !is.null(calib_result$final_values)) {
  cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║         SUCCESS - CALIBRATION COMPLETED!                     ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  # Show results
  calibrated_params <- calib_result$final_values
  
  param_table <- data.frame(
    Parameter = names(calibrated_params),
    Initial = param_info$init[names(calibrated_params)],
    Calibrated = as.numeric(calibrated_params),
    stringsAsFactors = FALSE
  )
  
  param_table$Change_Pct <- round(
    ((param_table$Calibrated - param_table$Initial) / param_table$Initial) * 100, 1
  )
  
  print(param_table, row.names = FALSE)
  
  cat("\nTime:", round(elapsed, 1), "minutes\n\n")
  
  # Save
  write.csv(param_table, file.path(output_dir, "parameters.csv"), row.names = FALSE)
  save(calib_result, file = file.path(output_dir, "calibration.RData"))
  
} else {
  cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║         CALIBRATION DID NOT COMPLETE                         ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
}

################################################################################
# EXPLANATION AND NEXT STEPS
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                   IMPORTANT INFORMATION                      ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("WHY THIS IS CHALLENGING:\n\n")

cat("1. DSSAT wrapper expects observations in DSSAT format:\n")
cat("   • *.WHA files (harvest/end-of-season data)\n")
cat("   • *.WHT files (time-series data)\n\n")

cat("2. Your observations are in CSV format:\n")
cat("   • C:/DSSAT48/data/Sakha95_observed_data_FINAL.csv\n\n")

cat("3. The CSV → DSSAT observation format conversion is needed\n\n")

cat("OPTIONS:\n\n")

cat("A. Convert CSV to DSSAT .WHT/.WHA files (RECOMMENDED)\n")
cat("   • Properly format as DSSAT observation files\n")
cat("   • Place in C:/DSSAT48/Wheat/\n")
cat("   • Then use read_obs() function\n\n")

cat("B. Modify DSSAT wrapper to accept CSV directly\n")
cat("   • Custom wrapper function\n")
cat("   • More complex but flexible\n\n")

cat("C. Use synthetic calibration approach\n")
cat("   • Test with DSSAT's example data first\n")
cat("   • Verify calibration works\n")
cat("   • Then adapt to your data\n\n")

cat("═══════════════════════════════════════════════════════════════\n\n")

################################################################################
# END
################################################################################

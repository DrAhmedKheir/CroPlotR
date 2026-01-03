################################################################################
# DIAGNOSTIC SCRIPT - Check DSSAT Experiment Files
# Run this BEFORE calibration to verify setup
################################################################################

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         DSSAT SETUP DIAGNOSTIC FOR SAKHA95                   ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# Load required packages
if(!require("DSSAT")){
  install.packages("DSSAT")
  library("DSSAT")
}

################################################################################
# 1. CHECK EXPERIMENT FILES
################################################################################

cat("1. Checking experiment files...\n\n")

# Check GMZA2001
gmza_file <- "C:/DSSAT48/Wheat/GMZA2001.WHX"
if (file.exists(gmza_file)) {
  cat("  ✓ GMZA2001.WHX exists\n")
  
  # Read experiment file
  gmza_exp <- DSSAT::read_dssat(gmza_file)
  
  # Get treatment numbers
  if ("TREATMENTS" %in% names(gmza_exp)) {
    gmza_treatments <- gmza_exp$TREATMENTS$N
    cat("    Treatments in GMZA2001.WHX:", paste(gmza_treatments, collapse = ", "), "\n")
    cat("    Total treatments:", length(gmza_treatments), "\n\n")
  }
} else {
  cat("  ✗ GMZA2001.WHX NOT FOUND!\n\n")
}

# Check SIDS2001
sids_file <- "C:/DSSAT48/Wheat/SIDS2001.WHX"
if (file.exists(sids_file)) {
  cat("  ✓ SIDS2001.WHX exists\n")
  
  # Read experiment file
  sids_exp <- DSSAT::read_dssat(sids_file)
  
  # Get treatment numbers
  if ("TREATMENTS" %in% names(sids_exp)) {
    sids_treatments <- sids_exp$TREATMENTS$N
    cat("    Treatments in SIDS2001.WHX:", paste(sids_treatments, collapse = ", "), "\n")
    cat("    Total treatments:", length(sids_treatments), "\n\n")
  }
} else {
  cat("  ✗ SIDS2001.WHX NOT FOUND!\n\n")
}

################################################################################
# 2. CHECK OBSERVED DATA
################################################################################

cat("2. Checking observed data...\n\n")

obs_file <- "C:/DSSAT48/data/Sakha95_observed_data.csv"
if (file.exists(obs_file)) {
  obs_raw <- read.csv(obs_file, stringsAsFactors = FALSE)
  
  cat("  ✓ Observed data loaded:", nrow(obs_raw), "observations\n\n")
  
  # Check GMZA treatments
  gmza_obs <- obs_raw[obs_raw$Experiment == "GMZA2001", ]
  gmza_obs_treatments <- unique(gsub("T", "", gmza_obs$Treatment))
  gmza_obs_treatments <- as.integer(gmza_obs_treatments)
  cat("    GMZA treatments in observed data:", paste(sort(gmza_obs_treatments), collapse = ", "), "\n")
  cat("    Total GMZA treatments:", length(gmza_obs_treatments), "\n\n")
  
  # Check SIDS treatments
  sids_obs <- obs_raw[obs_raw$Experiment == "SIDS2001", ]
  sids_obs_treatments <- unique(gsub("T", "", sids_obs$Treatment))
  sids_obs_treatments <- as.integer(sids_obs_treatments)
  cat("    SIDS treatments in observed data:", paste(sort(sids_obs_treatments), collapse = ", "), "\n")
  cat("    Total SIDS treatments:", length(sids_obs_treatments), "\n\n")
  
  # Check for mismatches
  if (exists("gmza_treatments")) {
    gmza_missing <- setdiff(gmza_obs_treatments, gmza_treatments)
    if (length(gmza_missing) > 0) {
      cat("  ⚠ GMZA treatments in data but NOT in .WHX file:", paste(gmza_missing, collapse = ", "), "\n")
    }
  }
  
  if (exists("sids_treatments")) {
    sids_missing <- setdiff(sids_obs_treatments, sids_treatments)
    if (length(sids_missing) > 0) {
      cat("  ⚠ SIDS treatments in data but NOT in .WHX file:", paste(sids_missing, collapse = ", "), "\n")
    }
  }
  
} else {
  cat("  ✗ Observed data NOT FOUND!\n\n")
}

################################################################################
# 3. CHECK ERROR.OUT IF EXISTS
################################################################################

cat("\n3. Checking for DSSAT errors...\n\n")

error_file <- "C:/DSSAT48/Wheat/ERROR.OUT"
if (file.exists(error_file)) {
  cat("  ⚠ ERROR.OUT file exists! Reading content:\n\n")
  cat("  ", paste(rep("─", 60), collapse = ""), "\n")
  errors <- readLines(error_file, warn = FALSE)
  cat("  ", paste(errors, collapse = "\n  "), "\n")
  cat("  ", paste(rep("─", 60), collapse = ""), "\n\n")
} else {
  cat("  ✓ No ERROR.OUT file (good!)\n\n")
}

################################################################################
# 4. CHECK CULTIVAR FILE
################################################################################

cat("4. Checking cultivar file...\n\n")

cul_file <- "C:/DSSAT48/Genotype/WHCER048.CUL"
if (file.exists(cul_file)) {
  cat("  ✓ WHCER048.CUL exists\n")
  
  cul_data <- DSSAT::read_cul(cul_file)
  
  # Check for SK0010
  if ("SK0010" %in% cul_data$`VAR-NAME`) {
    cat("  ✓ SK0010 (Sakha95) found in cultivar file\n")
    
    # Show current values
    idx <- which(cul_data$`VAR-NAME` == "SK0010")
    cat("\n    Current parameter values for SK0010:\n")
    params <- c("P1V", "P1D", "P5", "G1", "G2", "G3", "PHINT")
    for (p in params) {
      if (p %in% names(cul_data)) {
        cat(sprintf("      %-8s: %s\n", p, cul_data[[p]][idx]))
      }
    }
  } else {
    cat("  ✗ SK0010 NOT FOUND in cultivar file!\n")
  }
  
} else {
  cat("  ✗ WHCER048.CUL NOT FOUND!\n")
}

################################################################################
# 5. RECOMMENDATIONS
################################################################################

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                    RECOMMENDATIONS                           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

if (exists("gmza_missing") && length(gmza_missing) > 0) {
  cat("⚠ ACTION NEEDED for GMZA2001:\n")
  cat("  Your observed data has treatments:", paste(gmza_obs_treatments, collapse = ", "), "\n")
  cat("  But .WHX file only has:", paste(gmza_treatments, collapse = ", "), "\n")
  cat("  Missing treatments:", paste(gmza_missing, collapse = ", "), "\n\n")
  cat("  SOLUTION: Either:\n")
  cat("    a) Add missing treatments to GMZA2001.WHX file, OR\n")
  cat("    b) Remove these treatments from observed data\n\n")
}

if (exists("sids_missing") && length(sids_missing) > 0) {
  cat("⚠ ACTION NEEDED for SIDS2001:\n")
  cat("  Your observed data has treatments:", paste(sids_obs_treatments, collapse = ", "), "\n")
  cat("  But .WHX file only has:", paste(sids_treatments, collapse = ", "), "\n")
  cat("  Missing treatments:", paste(sids_missing, collapse = ", "), "\n\n")
  cat("  SOLUTION: Either:\n")
  cat("    a) Add missing treatments to SIDS2001.WHX file, OR\n")
  cat("    b) Remove these treatments from observed data\n\n")
}

if (file.exists(error_file)) {
  cat("⚠ DSSAT reported errors - check ERROR.OUT content above\n\n")
}

cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Run this diagnostic before attempting calibration!\n\n")

################################################################################
# END OF DIAGNOSTIC
################################################################################

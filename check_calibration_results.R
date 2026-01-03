################################################################################
# CHECK CALIBRATION RESULTS AND EXPERIMENT FILES
################################################################################

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         CHECKING CALIBRATION RESULTS                         ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

################################################################################
# 1. LOAD CALIBRATION RESULTS
################################################################################

cat("1. Loading calibration results...\n\n")

results_file <- "Sakha95_calibration_results/calibration_complete.RData"
if (file.exists(results_file)) {
  load(results_file)
  
  cat("  ✓ Results loaded\n\n")
  
  # Check what's in calib_result
  cat("  Calibration result structure:\n")
  cat("    Names:", paste(names(calib_result), collapse = ", "), "\n\n")
  
  # Check final values
  if (!is.null(calib_result$final_values)) {
    cat("  Final parameter values:\n")
    print(calib_result$final_values)
    cat("\n")
  } else {
    cat("  ⚠ No final_values in result!\n\n")
  }
  
  # Check if there's an error message
  if (!is.null(calib_result$error)) {
    cat("  Error status:", calib_result$error, "\n\n")
  }
  
} else {
  cat("  ✗ Results file not found!\n\n")
}

################################################################################
# 2. CHECK BOTH EXPERIMENT FILES FOR ACTUAL TREATMENTS
################################################################################

cat("2. Checking actual treatments in experiment files...\n\n")

library(DSSAT)

# GMZA2001
gmza_file <- "C:/DSSAT48/Wheat/GMZA2001.WHX"
cat("  Reading GMZA2001.WHX...\n")
gmza_content <- readLines(gmza_file)

# Find treatment lines
gmza_trt_start <- grep("\\*TREATMENTS", gmza_content)
if (length(gmza_trt_start) > 0) {
  # Treatments usually start 2 lines after *TREATMENTS
  trt_section_start <- gmza_trt_start + 2
  
  # Find where treatments end (next section or blank lines)
  trt_lines <- gmza_content[trt_section_start:length(gmza_content)]
  
  # Extract treatment numbers (first column)
  gmza_trt_nums <- c()
  for (line in trt_lines) {
    if (nchar(trimws(line)) == 0 || grepl("^\\*", line) || grepl("^@", line)) {
      break
    }
    # First number in the line
    parts <- strsplit(trimws(line), "\\s+")[[1]]
    if (length(parts) > 0 && !is.na(as.numeric(parts[1]))) {
      gmza_trt_nums <- c(gmza_trt_nums, as.integer(parts[1]))
    }
  }
  
  cat("    GMZA2001 treatments:", paste(sort(gmza_trt_nums), collapse = ", "), "\n")
  cat("    Total:", length(gmza_trt_nums), "treatments\n\n")
}

# SIDS2001
sids_file <- "C:/DSSAT48/Wheat/SIDS2001.WHX"
cat("  Reading SIDS2001.WHX...\n")
sids_content <- readLines(sids_file)

# Find treatment lines
sids_trt_start <- grep("\\*TREATMENTS", sids_content)
if (length(sids_trt_start) > 0) {
  trt_section_start <- sids_trt_start + 2
  
  trt_lines <- sids_content[trt_section_start:length(sids_content)]
  
  sids_trt_nums <- c()
  for (line in trt_lines) {
    if (nchar(trimws(line)) == 0 || grepl("^\\*", line) || grepl("^@", line)) {
      break
    }
    parts <- strsplit(trimws(line), "\\s+")[[1]]
    if (length(parts) > 0 && !is.na(as.numeric(parts[1]))) {
      sids_trt_nums <- c(sids_trt_nums, as.integer(parts[1]))
    }
  }
  
  cat("    SIDS2001 treatments:", paste(sort(sids_trt_nums), collapse = ", "), "\n")
  cat("    Total:", length(sids_trt_nums), "treatments\n\n")
}

################################################################################
# 3. COMPARE WITH OBSERVED DATA
################################################################################

cat("3. Comparing with observed data...\n\n")

obs_file <- "C:/DSSAT48/data/Sakha95_observed_data_filtered.csv"
obs <- read.csv(obs_file)

# Extract treatment numbers
obs$TreatmentNum <- as.integer(gsub("T", "", obs$Treatment))

# GMZA
gmza_obs <- obs[obs$Experiment == "GMZA2001", ]
gmza_obs_trts <- sort(unique(gmza_obs$TreatmentNum))
cat("  GMZA observed data treatments:", paste(gmza_obs_trts, collapse = ", "), "\n")

if (exists("gmza_trt_nums")) {
  gmza_missing <- setdiff(gmza_obs_trts, gmza_trt_nums)
  if (length(gmza_missing) > 0) {
    cat("  ⚠ GMZA missing in .WHX:", paste(gmza_missing, collapse = ", "), "\n")
  } else {
    cat("  ✓ All GMZA treatments exist in .WHX\n")
  }
}
cat("\n")

# SIDS
sids_obs <- obs[obs$Experiment == "SIDS2001", ]
sids_obs_trts <- sort(unique(sids_obs$TreatmentNum))
cat("  SIDS observed data treatments:", paste(sids_obs_trts, collapse = ", "), "\n")

if (exists("sids_trt_nums")) {
  sids_missing <- setdiff(sids_obs_trts, sids_trt_nums)
  if (length(sids_missing) > 0) {
    cat("  ⚠ SIDS missing in .WHX:", paste(sids_missing, collapse = ", "), "\n")
  } else {
    cat("  ✓ All SIDS treatments exist in .WHX\n")
  }
}
cat("\n")

################################################################################
# 4. CHECK ERROR.OUT
################################################################################

cat("4. Checking ERROR.OUT...\n\n")

error_file <- "C:/DSSAT48/Wheat/ERROR.OUT"
if (file.exists(error_file)) {
  cat("  ⚠ ERROR.OUT exists. Recent errors:\n\n")
  error_lines <- readLines(error_file)
  # Show last 30 lines
  start_line <- max(1, length(error_lines) - 30)
  cat("  ", paste(error_lines[start_line:length(error_lines)], collapse = "\n  "), "\n\n")
} else {
  cat("  ✓ No ERROR.OUT file\n\n")
}

################################################################################
# RECOMMENDATIONS
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                    RECOMMENDATIONS                           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

if (exists("gmza_missing") && length(gmza_missing) > 0) {
  cat("⚠ Need to remove GMZA treatments:", paste(gmza_missing, collapse = ", "), "\n")
}

if (exists("sids_missing") && length(sids_missing) > 0) {
  cat("⚠ Need to remove SIDS treatments:", paste(sids_missing, collapse = ", "), "\n")
}

if ((exists("gmza_missing") && length(gmza_missing) > 0) ||
    (exists("sids_missing") && length(sids_missing) > 0)) {
  cat("\nACTION: Run the updated filter script to remove these treatments\n")
}

cat("\n═══════════════════════════════════════════════════════════════\n\n")

################################################################################
# END
################################################################################

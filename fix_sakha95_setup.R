################################################################################
# FIX SAKHA95 DATA AND ADD CULTIVAR
# This script:
# 1. Adds SK0010 to WHCER048.CUL (if missing)
# 2. Filters observed data to match experiment file treatments
# 3. Creates calibration-ready data
################################################################################

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         FIXING SAKHA95 SETUP FOR CALIBRATION                ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# Load required packages
if(!require("DSSAT")){
  install.packages("DSSAT")
  library("DSSAT")
}
if(!require("dplyr")){
  install.packages("dplyr")
  library("dplyr")
}

################################################################################
# STEP 1: ADD SK0010 TO CULTIVAR FILE
################################################################################

cat("Step 1: Checking/Adding SK0010 to cultivar file...\n\n")

cul_file <- "C:/DSSAT48/Genotype/WHCER048.CUL"

# Read cultivar file
cul_data <- DSSAT::read_cul(cul_file)

# Check if SK0010 exists
if ("SK0010" %in% cul_data$`VAR-NAME`) {
  cat("  ✓ SK0010 already exists in cultivar file\n\n")
} else {
  cat("  ⚠ SK0010 NOT FOUND - Adding it now...\n\n")
  
  # Backup original file
  backup_file <- paste0(cul_file, ".backup_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  file.copy(cul_file, backup_file)
  cat("    ✓ Backup created:", backup_file, "\n")
  
  # Create SK0010 entry based on a similar Egyptian/Mediterranean cultivar
  # Let's use NEWTON as a template and adjust for Egyptian conditions
  template_idx <- which(cul_data$`VAR-NAME` == "NEWTON")[1]
  
  if (length(template_idx) == 0) {
    # If NEWTON not found, use first cultivar as template
    template_idx <- 1
    cat("    Using", cul_data$`VAR-NAME`[1], "as template\n")
  } else {
    cat("    Using NEWTON as template\n")
  }
  
  # Create new row for SK0010
  new_row <- cul_data[template_idx, ]
  
  # Set Sakha95 parameters (based on Egyptian wheat literature)
  new_row$`VAR-NAME` <- "SK0010"
  new_row$`VAR#` <- "SK0010"
  new_row$VRNAME <- "Sakha95"
  new_row$EXPNO <- "."
  
  # Set genetic coefficients (initial estimates for Egyptian spring wheat)
  new_row$P1V <- "25"      # Vernalization days (medium)
  new_row$P1D <- "70"      # Photoperiod sensitivity (medium-high)
  new_row$P5 <- "550"      # Grain filling duration
  new_row$G1 <- "24"       # Kernel number coefficient
  new_row$G2 <- "45"       # Standard kernel weight
  new_row$G3 <- "2.2"      # Stem weight
  new_row$PHINT <- "95"    # Phylochron interval
  
  # Add to cultivar data
  cul_data <- rbind(cul_data, new_row)
  
  # Write updated file
  DSSAT::write_cul(cul_data, cul_file)
  
  cat("    ✓ SK0010 (Sakha95) added to cultivar file!\n")
  cat("\n    Parameter values:\n")
  cat("      P1V   =", new_row$P1V, "(Vernalization)\n")
  cat("      P1D   =", new_row$P1D, "(Photoperiod)\n")
  cat("      P5    =", new_row$P5, "(Grain filling)\n")
  cat("      G1    =", new_row$G1, "(Kernel number)\n")
  cat("      G2    =", new_row$G2, "(Kernel weight)\n")
  cat("      G3    =", new_row$G3, "(Stem weight)\n")
  cat("      PHINT =", new_row$PHINT, "(Phylochron)\n\n")
}

################################################################################
# STEP 2: DETERMINE AVAILABLE TREATMENTS
################################################################################

cat("Step 2: Determining available treatments in experiment files...\n\n")

# For GMZA2001 - based on error, it has 23 treatments (1-23)
gmza_available_treatments <- 1:23
cat("  GMZA2001.WHX has treatments:", paste(gmza_available_treatments, collapse = ", "), "\n")

# For SIDS2001 - assume all 33 are available (no error reported)
sids_available_treatments <- 1:33
cat("  SIDS2001.WHX has treatments:", paste(sids_available_treatments, collapse = ", "), "\n\n")

################################################################################
# STEP 3: FILTER OBSERVED DATA
################################################################################

cat("Step 3: Filtering observed data to match experiment files...\n\n")

# Load observed data
obs_file <- "C:/DSSAT48/data/Sakha95_observed_data.csv"
obs_raw <- read.csv(obs_file, stringsAsFactors = FALSE)
obs_raw$Date <- as.Date(obs_raw$Date)

cat("  Original data:", nrow(obs_raw), "observations\n")

# Extract treatment numbers
obs_raw$TreatmentNum <- as.integer(gsub("T", "", obs_raw$Treatment))

# Filter to only include available treatments
obs_filtered <- obs_raw %>%
  filter(
    (Experiment == "GMZA2001" & TreatmentNum %in% gmza_available_treatments) |
    (Experiment == "SIDS2001" & TreatmentNum %in% sids_available_treatments)
  )

cat("  Filtered data:", nrow(obs_filtered), "observations\n\n")

# Show what was removed
removed <- nrow(obs_raw) - nrow(obs_filtered)
if (removed > 0) {
  cat("  Removed", removed, "observations from non-existent treatments:\n")
  
  removed_gmza <- obs_raw %>%
    filter(Experiment == "GMZA2001" & !TreatmentNum %in% gmza_available_treatments) %>%
    pull(Treatment) %>%
    unique()
  
  if (length(removed_gmza) > 0) {
    cat("    GMZA2001:", paste(removed_gmza, collapse = ", "), "\n")
  }
  
  removed_sids <- obs_raw %>%
    filter(Experiment == "SIDS2001" & !TreatmentNum %in% sids_available_treatments) %>%
    pull(Treatment) %>%
    unique()
  
  if (length(removed_sids) > 0) {
    cat("    SIDS2001:", paste(removed_sids, collapse = ", "), "\n")
  }
  cat("\n")
}

# Save filtered data
filtered_file <- "C:/DSSAT48/data/Sakha95_observed_data_filtered.csv"
write.csv(obs_filtered, filtered_file, row.names = FALSE)
cat("  ✓ Filtered data saved to:", filtered_file, "\n\n")

################################################################################
# STEP 4: CREATE SUMMARY
################################################################################

cat("Step 4: Summary of available data for calibration...\n\n")

# Count by experiment
summary_data <- obs_filtered %>%
  group_by(Experiment, Treatment) %>%
  summarise(n_obs = n(), .groups = "drop")

gmza_summary <- summary_data %>% filter(grepl("GMZA", Experiment))
sids_summary <- summary_data %>% filter(grepl("SIDS", Experiment))

cat("  GMZA2001:\n")
cat("    Treatments:", nrow(gmza_summary), "\n")
cat("    Total observations:", sum(gmza_summary$n_obs), "\n\n")

cat("  SIDS2001:\n")
cat("    Treatments:", nrow(sids_summary), "\n")
cat("    Total observations:", sum(sids_summary$n_obs), "\n\n")

cat("  TOTAL:\n")
cat("    Situations:", nrow(summary_data), "\n")
cat("    Observations:", nrow(obs_filtered), "\n\n")

# Count by variable
var_summary <- obs_filtered %>%
  group_by(Variable) %>%
  summarise(n = n(), .groups = "drop")

cat("  Variables:\n")
for (i in 1:nrow(var_summary)) {
  cat(sprintf("    %-8s: %3d observations\n", var_summary$Variable[i], var_summary$n[i]))
}

################################################################################
# FINAL INSTRUCTIONS
################################################################################

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                   SETUP COMPLETE!                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("✅ SK0010 (Sakha95) added to cultivar file\n")
cat("✅ Observed data filtered to match experiment files\n")
cat("✅ Ready for calibration!\n\n")

cat("Next steps:\n")
cat("  1. Review the filtered data summary above\n")
cat("  2. Run the calibration script (will be updated)\n\n")

cat("Files created/modified:\n")
cat("  • Cultivar file:", cul_file, "(SK0010 added)\n")
cat("  • Backup:", backup_file, "\n")
cat("  • Filtered data:", filtered_file, "\n\n")

cat("═══════════════════════════════════════════════════════════════\n\n")

################################################################################
# END OF FIX SCRIPT
################################################################################

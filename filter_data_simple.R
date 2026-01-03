################################################################################
# SIMPLE FIX - FILTER DATA TO MATCH EXPERIMENT FILES
# SK0010 already exists, just need to filter observed data
################################################################################

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         FILTERING DATA TO MATCH EXPERIMENT FILES            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

library(dplyr)

################################################################################
# STEP 1: VERIFY SK0010 EXISTS
################################################################################

cat("Step 1: Verifying SK0010 in cultivar file...\n\n")

cul_file <- "C:/DSSAT48/Genotype/WHCER048.CUL"
cul_lines <- readLines(cul_file)

# Search for SK0010
sk0010_line <- grep("^SK0010", cul_lines, value = TRUE)

if (length(sk0010_line) > 0) {
  cat("  ✓ SK0010 (Sakha95) found in cultivar file:\n")
  cat("   ", sk0010_line[1], "\n\n")
  
  # Parse the values (space-separated)
  parts <- strsplit(trimws(sk0010_line[1]), "\\s+")[[1]]
  cat("    Current parameter values:\n")
  cat("      VAR-NAME:", parts[1], "\n")
  cat("      VRNAME  :", parts[2], "\n")
  cat("      EXPNO   :", parts[3], "\n")
  cat("      P1V     :", parts[4], "\n")
  cat("      P1D     :", parts[5], "\n")
  cat("      P5      :", parts[6], "\n")
  cat("      G1      :", parts[7], "\n")
  cat("      G2      :", parts[8], "\n")
  cat("      G3      :", parts[9], "\n")
  cat("      PHINT   :", parts[10], "\n\n")
} else {
  cat("  ✗ SK0010 NOT FOUND!\n\n")
  stop("SK0010 must be in cultivar file before proceeding.")
}

################################################################################
# STEP 2: DETERMINE AVAILABLE TREATMENTS
################################################################################

cat("Step 2: Determining available treatments...\n\n")

# Based on ERROR.OUT: GMZA2001 has treatments 1-23 only
gmza_available <- 1:23
cat("  GMZA2001.WHX has treatments 1-23 (23 treatments)\n")

# SIDS2001 has all 33 treatments (no error reported)
sids_available <- 1:33
cat("  SIDS2001.WHX has treatments 1-33 (33 treatments)\n\n")

################################################################################
# STEP 3: FILTER OBSERVED DATA
################################################################################

cat("Step 3: Filtering observed data...\n\n")

# Load original data
obs_file <- "C:/DSSAT48/data/Sakha95_observed_data.csv"
obs_raw <- read.csv(obs_file, stringsAsFactors = FALSE)
obs_raw$Date <- as.Date(obs_raw$Date)

cat("  Original data:", nrow(obs_raw), "observations\n")

# Extract treatment numbers
obs_raw$TreatmentNum <- as.integer(gsub("T", "", obs_raw$Treatment))

# Filter
obs_filtered <- obs_raw %>%
  filter(
    (Experiment == "GMZA2001" & TreatmentNum %in% gmza_available) |
    (Experiment == "SIDS2001" & TreatmentNum %in% sids_available)
  )

cat("  Filtered data:", nrow(obs_filtered), "observations\n")

# Show removed treatments
removed_count <- nrow(obs_raw) - nrow(obs_filtered)
if (removed_count > 0) {
  cat("\n  Removed", removed_count, "observations from these treatments:\n")
  
  removed_gmza <- obs_raw %>%
    filter(Experiment == "GMZA2001", !TreatmentNum %in% gmza_available) %>%
    select(Treatment) %>%
    distinct() %>%
    pull()
  
  if (length(removed_gmza) > 0) {
    cat("    GMZA2001:", paste(removed_gmza, collapse = ", "), 
        "(not in experiment file)\n")
  }
}

cat("\n")

# Save filtered data
output_file <- "C:/DSSAT48/data/Sakha95_observed_data_filtered.csv"
write.csv(obs_filtered %>% select(-TreatmentNum), output_file, row.names = FALSE)
cat("  ✓ Filtered data saved to:\n")
cat("   ", output_file, "\n\n")

################################################################################
# STEP 4: SUMMARY
################################################################################

cat("Step 4: Summary for calibration...\n\n")

# Situations summary
situations_summary <- obs_filtered %>%
  group_by(Experiment) %>%
  summarise(
    n_treatments = n_distinct(Treatment),
    n_obs = n(),
    .groups = "drop"
  )

print(situations_summary)
cat("\n")

# Variables summary
variables_summary <- obs_filtered %>%
  group_by(Variable) %>%
  summarise(n_obs = n(), .groups = "drop")

cat("  Variables available:\n")
for (i in 1:nrow(variables_summary)) {
  cat(sprintf("    %-8s: %3d observations\n", 
              variables_summary$Variable[i], 
              variables_summary$n_obs[i]))
}

cat("\n")

# Total situations
total_situations <- obs_filtered %>%
  select(Experiment, Treatment) %>%
  distinct() %>%
  nrow()

cat("  Total situations for calibration:", total_situations, "\n")
cat("  Total observations:", nrow(obs_filtered), "\n\n")

################################################################################
# FINAL MESSAGE
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                   SETUP COMPLETE!                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("✅ SK0010 (Sakha95) verified in cultivar file\n")
cat("✅ Observed data filtered to match experiment files\n")
cat("✅ ", total_situations, "situations ready for calibration\n")
cat("✅ ", nrow(obs_filtered), "observations ready\n\n")

cat("Next step:\n")
cat("  Run the updated calibration script!\n\n")

cat("═══════════════════════════════════════════════════════════════\n\n")

################################################################################
# END
################################################################################

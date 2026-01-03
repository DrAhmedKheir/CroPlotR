################################################################################
# FINAL DATA FILTER - CORRECT TREATMENT COUNTS
# GMZA: 1-23 (23 treatments)
# SIDS: 1-27 (27 treatments) NOT 33!
################################################################################

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║    FINAL DATA FILTER - MATCHING EXPERIMENT FILES            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

library(dplyr)
library(tidyr)

################################################################################
# FILTER TO CORRECT TREATMENTS
################################################################################

cat("Filtering observed data to match experiment files...\n\n")

# Load original data
obs_file <- "C:/DSSAT48/data/Sakha95_observed_data.csv"
obs_raw <- read.csv(obs_file, stringsAsFactors = FALSE)
obs_raw$Date <- as.Date(obs_raw$Date)

cat("  Original data:", nrow(obs_raw), "observations\n")

# Extract treatment numbers
obs_raw$TreatmentNum <- as.integer(gsub("T", "", obs_raw$Treatment))

# CORRECT TREATMENT RANGES
gmza_available <- 1:23  # GMZA2001.WHX has 23 treatments
sids_available <- 1:27  # SIDS2001.WHX has 27 treatments (NOT 33!)

cat("  GMZA2001: treatments 1-23\n")
cat("  SIDS2001: treatments 1-27\n\n")

# Filter
obs_final <- obs_raw %>%
  filter(
    (Experiment == "GMZA2001" & TreatmentNum %in% gmza_available) |
    (Experiment == "SIDS2001" & TreatmentNum %in% sids_available)
  ) %>%
  select(-TreatmentNum)  # Remove helper column

cat("  Filtered data:", nrow(obs_final), "observations\n")

# Show what was removed
removed <- nrow(obs_raw) - nrow(obs_final)
cat("  Removed:", removed, "observations\n\n")

if (removed > 0) {
  # Show removed GMZA treatments
  removed_gmza <- obs_raw %>%
    filter(Experiment == "GMZA2001") %>%
    mutate(TreatmentNum = as.integer(gsub("T", "", Treatment))) %>%
    filter(!TreatmentNum %in% gmza_available) %>%
    pull(Treatment) %>%
    unique()
  
  if (length(removed_gmza) > 0) {
    cat("  Removed GMZA treatments:", paste(removed_gmza, collapse = ", "), "\n")
  }
  
  # Show removed SIDS treatments
  removed_sids <- obs_raw %>%
    filter(Experiment == "SIDS2001") %>%
    mutate(TreatmentNum = as.integer(gsub("T", "", Treatment))) %>%
    filter(!TreatmentNum %in% sids_available) %>%
    pull(Treatment) %>%
    unique()
  
  if (length(removed_sids) > 0) {
    cat("  Removed SIDS treatments:", paste(removed_sids, collapse = ", "), "\n")
  }
  cat("\n")
}

# Save final filtered data
output_file <- "C:/DSSAT48/data/Sakha95_observed_data_FINAL.csv"
write.csv(obs_final, output_file, row.names = FALSE)

cat("✓ Final data saved to:\n")
cat("  ", output_file, "\n\n")

################################################################################
# SUMMARY
################################################################################

cat("Summary of final calibration data:\n\n")

# By experiment
summary_exp <- obs_final %>%
  group_by(Experiment) %>%
  summarise(
    n_treatments = n_distinct(Treatment),
    n_obs = n(),
    .groups = "drop"
  )

print(summary_exp)
cat("\n")

# By variable
summary_var <- obs_final %>%
  group_by(Variable) %>%
  summarise(n = n(), .groups = "drop")

cat("Variables:\n")
for (i in 1:nrow(summary_var)) {
  cat(sprintf("  %-8s: %3d observations\n", 
              summary_var$Variable[i], summary_var$n[i]))
}
cat("\n")

# Total situations
total_sits <- obs_final %>%
  select(Experiment, Treatment) %>%
  distinct() %>%
  nrow()

cat("TOTAL FOR CALIBRATION:\n")
cat("  Situations:", total_sits, "(23 GMZA + 27 SIDS)\n")
cat("  Observations:", nrow(obs_final), "\n\n")

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                  DATA READY FOR CALIBRATION!                 ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("✅ GMZA: 23 treatments (all match experiment file)\n")
cat("✅ SIDS: 27 treatments (all match experiment file)\n")
cat("✅ Total: 50 situations ready\n\n")

cat("Next: Run the final calibration script!\n\n")

################################################################################
# END
################################################################################

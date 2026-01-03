################################################################################
# INVESTIGATE CALIBRATION FAILURE
################################################################################

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║      INVESTIGATING WHY CALIBRATION FAILED                    ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

################################################################################
# 1. LOAD PARTIAL RESULTS
################################################################################

cat("1. Loading partial calibration results...\n\n")

if (file.exists("Sakha95_FINAL_results/optim_results.Rdata")) {
  load("Sakha95_FINAL_results/optim_results.Rdata")
  
  cat("  ✓ Partial results loaded\n")
  cat("  Contents:", paste(ls(), collapse = ", "), "\n\n")
  
  if (exists("optim_results")) {
    cat("  optim_results structure:\n")
    print(str(optim_results, max.level = 2))
    cat("\n")
  }
}

################################################################################
# 2. TEST DSSAT WRAPPER DIRECTLY
################################################################################

cat("2. Testing DSSAT wrapper directly...\n\n")

library(dplyr)
library(tidyr)

# Load wrapper
if (file.exists("DSSAT_wrapper.R")) {
  source("DSSAT_wrapper.R", verbose = FALSE)
} else {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
}

# Model options
model_options <- list(
  DSSAT_path = 'C:/DSSAT48',
  DSSAT_exe = 'DSCSM048.EXE',
  Crop = "Wheat",
  ecotype_filename = "WHCER048.ECO",
  cultivar_filename = "WHCER048.CUL",
  ecotype = "CAWH01",
  cultivar = "SK0010",
  suppress_output = TRUE
)

# Load data
obs_file <- "C:/DSSAT48/data/Sakha95_observed_data_FINAL.csv"
obs_raw <- read.csv(obs_file, stringsAsFactors = FALSE)
obs_raw$Date <- as.Date(obs_raw$Date)

# Format for CroptimizR
obs_list <- list()

for (exp in unique(obs_raw$Experiment)) {
  exp_data <- obs_raw[obs_raw$Experiment == exp, ]
  
  for (trt in unique(exp_data$Treatment)) {
    trno <- as.integer(gsub("T", "", trt))
    sit_name <- paste0(exp, "_", trno)
    
    treat_data <- exp_data[exp_data$Treatment == trt, ]
    
    obs_wide <- treat_data %>%
      select(Date, Variable, Value) %>%
      pivot_wider(names_from = Variable, values_from = Value,
                  values_fn = list(Value = mean))
    
    obs_list[[sit_name]] <- as.data.frame(obs_wide)
  }
}

situation_names <- names(obs_list)

cat("  Loaded", length(obs_list), "situations\n\n")

# Test with just 2 situations
test_situations <- situation_names[1:2]

cat("  Testing wrapper with 2 situations:", paste(test_situations, collapse = ", "), "\n\n")

# Test with default parameters (NULL)
test_result <- tryCatch({
  DSSAT_wrapper(
    param_values = NULL,
    model_options = model_options,
    situation = test_situations
  )
}, error = function(e) {
  cat("  ❌ Error:", as.character(e), "\n\n")
  return(list(error = TRUE))
})

if (!test_result$error) {
  cat("  ✓ Wrapper ran successfully!\n")
  cat("    Situations simulated:", length(test_result$sim_list), "\n")
  
  # Check structure
  if (length(test_result$sim_list) > 0) {
    first_sim <- test_result$sim_list[[1]]
    cat("    First simulation columns:", paste(names(first_sim), collapse = ", "), "\n")
    cat("    First simulation rows:", nrow(first_sim), "\n\n")
  }
} else {
  cat("  ❌ Wrapper failed!\n\n")
}

################################################################################
# 3. CHECK OBSERVATIONS FORMAT
################################################################################

cat("3. Checking observations format...\n\n")

cat("  First observation structure:\n")
print(str(obs_list[[1]]))
cat("\n")

cat("  Sample of first observation:\n")
print(head(obs_list[[1]], 3))
cat("\n")

# Check for NAs
na_count <- sum(is.na(obs_list[[1]]))
cat("  NA values in first observation:", na_count, "\n\n")

################################################################################
# 4. CHECK WARNINGS
################################################################################

cat("4. Checking recent warnings...\n\n")

warns <- warnings()
if (length(warns) > 0) {
  cat("  Recent warnings (first 10):\n")
  for (i in 1:min(10, length(warns))) {
    cat("    ", i, ":", warns[[i]], "\n")
  }
  cat("\n")
} else {
  cat("  No warnings stored\n\n")
}

################################################################################
# DIAGNOSIS
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                      DIAGNOSIS                               ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("The calibration is failing because:\n\n")
cat("1. CroptimizR's optimization is stopping after only 5 evaluations\n")
cat("2. Error: 'obs_sim_list$obs_list : $ operator is invalid'\n")
cat("3. This suggests obs_list format incompatibility\n\n")

cat("Likely causes:\n")
cat("  • obs_list structure doesn't match CroptimizR expectations\n")
cat("  • Date format issues in observations\n")
cat("  • Variable name mismatches\n")
cat("  • NA handling problems\n\n")

cat("Next step: Try simpler optimization method or fix obs format\n\n")

################################################################################
# END
################################################################################

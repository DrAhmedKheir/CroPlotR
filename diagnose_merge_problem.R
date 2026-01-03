################################################################################
# DIAGNOSE WHY OBSERVATIONS DON'T MATCH SIMULATIONS
################################################################################

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         DIAGNOSING OBSERVATION/SIMULATION MISMATCH           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

# Load functions
if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
  source("R/read_obs.R", verbose = FALSE)
} else {
  source("DSSAT_wrapper.R", verbose = FALSE)
}

################################################################################
# 1. READ OBSERVATIONS
################################################################################

cat("1. Reading observations from .WHA files...\n\n")

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

# Just test first 2 situations
test_situations <- c("GMZA2001_1", "GMZA2001_2")

obs_list <- read_obs(
  model_options = model_options,
  situation = test_situations,
  read_end_season = TRUE
)

cat("  Observations loaded for", length(obs_list), "situations\n\n")

# Show first observation
cat("  First observation (GMZA2001_1):\n")
print(obs_list[[1]])
cat("\n")

################################################################################
# 2. RUN SIMULATION
################################################################################

cat("2. Running simulation for same situations...\n\n")

param_values <- c(P1V=16, P1D=74.6, P5=660, G1=47, G2=80, G3=0.8, PHINT=131)

sim_result <- DSSAT_wrapper(
  param_values = param_values,
  model_options = model_options,
  situation = test_situations
)

if (sim_result$error) {
  cat("  ⚠ Simulation had errors!\n\n")
} else {
  cat("  ✓ Simulation completed\n\n")
}

# Show first simulation
cat("  First simulation (GMZA2001_1):\n")
cat("    Rows:", nrow(sim_result$sim_list[[1]]), "\n")
cat("    Columns:", ncol(sim_result$sim_list[[1]]), "\n")
cat("    Date range:", 
    min(sim_result$sim_list[[1]]$Date), "to",
    max(sim_result$sim_list[[1]]$Date), "\n\n")

cat("  Sample of simulation output:\n")
print(head(sim_result$sim_list[[1]][, c("Date", "HWAM", "H#AM", "ADAT", "HWUM")], 5))
cat("\n")

################################################################################
# 3. TRY TO MERGE
################################################################################

cat("3. Attempting to merge observations and simulations...\n\n")

sit <- "GMZA2001_1"
obs_data <- obs_list[[sit]]
sim_data <- sim_result$sim_list[[sit]]

cat("  Observation dates:\n")
print(obs_data$Date)
cat("\n")

cat("  Simulation dates (last 10):\n")
print(tail(sim_data$Date, 10))
cat("\n")

# Try merge
merged <- merge(obs_data, sim_data, by = "Date", suffixes = c("_obs", "_sim"))

cat("  Merged data:\n")
if (nrow(merged) == 0) {
  cat("    ⚠ NO ROWS after merge! Dates don't match!\n\n")
  
  cat("  Closest simulation date to observation:\n")
  obs_date <- obs_data$Date[1]
  sim_dates <- sim_data$Date
  closest_idx <- which.min(abs(as.numeric(sim_dates - obs_date)))
  cat("    Observation date:", obs_date, "\n")
  cat("    Closest sim date:", sim_dates[closest_idx], "\n")
  cat("    Difference:", as.numeric(sim_dates[closest_idx] - obs_date), "days\n\n")
  
} else {
  cat("    ✓ Merged successfully:", nrow(merged), "rows\n")
  print(merged)
  cat("\n")
}

################################################################################
# 4. CHECK VARIABLE NAMES
################################################################################

cat("4. Checking variable names...\n\n")

obs_vars <- setdiff(names(obs_data), "Date")
sim_vars <- names(sim_data)

cat("  Variables in observations:", paste(obs_vars, collapse = ", "), "\n")
cat("  Variables in simulation:\n    ", paste(head(sim_vars, 20), collapse = ", "), "\n    ...\n\n")

for (var in obs_vars) {
  if (var %in% sim_vars) {
    cat("  ✓", var, "exists in simulation\n")
  } else {
    cat("  ✗", var, "NOT in simulation\n")
  }
}
cat("\n")

################################################################################
# DIAGNOSIS
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                      DIAGNOSIS                               ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

if (nrow(merged) == 0) {
  cat("PROBLEM: Observation dates don't match simulation dates!\n\n")
  
  cat("EXPLANATION:\n")
  cat("  • .WHA files contain harvest date observations\n")
  cat("  • DSSAT simulations output daily data\n")
  cat("  • The harvest DATE in observations may not exactly match\n")
  cat("    the date DSSAT outputs the harvest variables\n\n")
  
  cat("SOLUTION:\n")
  cat("  Use sit_var_dates_mask argument in DSSAT_wrapper\n")
  cat("  OR find closest simulation date to observation date\n\n")
  
} else {
  cat("✓ Dates match! Merge successful!\n\n")
  
  # Calculate RMSE
  total_sse <- 0
  n_obs <- 0
  
  for (var in c("HWAM", "H#AM", "ADAT", "HWUM")) {
    obs_col <- paste0(var, "_obs")
    sim_col <- var
    
    if (obs_col %in% names(merged) && sim_col %in% names(merged)) {
      obs_vals <- merged[[obs_col]]
      sim_vals <- merged[[sim_col]]
      
      valid <- !is.na(obs_vals) & !is.na(sim_vals)
      
      if (sum(valid) > 0) {
        sse <- sum((obs_vals[valid] - sim_vals[valid])^2)
        total_sse <- total_sse + sse
        n_obs <- n_obs + sum(valid)
        
        cat("  ", var, ":\n")
        cat("    Observed:", obs_vals[valid], "\n")
        cat("    Simulated:", sim_vals[valid], "\n")
        cat("    Difference:", obs_vals[valid] - sim_vals[valid], "\n\n")
      }
    }
  }
  
  if (n_obs > 0) {
    rmse <- sqrt(total_sse / n_obs)
    cat("  RMSE for this situation:", round(rmse, 2), "\n\n")
  }
}

cat("═══════════════════════════════════════════════════════════════\n\n")

################################################################################
# END
################################################################################

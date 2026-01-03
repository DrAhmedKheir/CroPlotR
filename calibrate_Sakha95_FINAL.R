################################################################################
# SAKHA95 WHEAT CALIBRATION - FINAL WORKING VERSION
# Multi-Site: Gemiza (23 treatments) + Sids (33 treatments) = 56 situations
# Using FILTERED data and existing SK0010 cultivar
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  SAKHA95 WHEAT CALIBRATION - REAL DSSAT WITH CroptimizR     ║\n")
cat("║  Gemiza (23 trt) + Sids (33 trt) = 56 situations            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# STEP 1: LOAD PACKAGES
################################################################################

cat("Step 1: Loading required packages...\n")

if(!require("CroptimizR", quietly = TRUE)){   
  if(!require("devtools")){
    install.packages("devtools")
  }
  devtools::install_github("SticsRPacks/CroptimizR@*release")
  library("CroptimizR")
}

if(!require("CroPlotR", quietly = TRUE)){
  if(!require("devtools")){
    install.packages("devtools")
  }
  devtools::install_github("SticsRPacks/CroPlotR@*release")
  library("CroPlotR")
}

library(dplyr, quietly = TRUE)
library(tidyr, quietly = TRUE)

cat("✓ All packages loaded\n\n")

################################################################################
# STEP 2: SOURCE DSSAT WRAPPER
################################################################################

cat("Step 2: Loading DSSAT wrapper...\n")

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

if (file.exists("DSSAT_wrapper.R")) {
  source("DSSAT_wrapper.R")
  cat("✓ Wrapper loaded from: DSSAT_wrapper.R\n\n")
} else if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R")
  cat("✓ Wrapper loaded from: R/DSSAT_wrapper.R\n\n")
} else {
  stop("ERROR: DSSAT_wrapper.R not found!")
}

################################################################################
# STEP 3: CONFIGURE MODEL OPTIONS
################################################################################

cat("Step 3: Configuring model options...\n")

model_options <- list()
model_options$DSSAT_path <- 'C:/DSSAT48'
model_options$DSSAT_exe <- 'DSCSM048.EXE'
model_options$Crop <- "Wheat"
model_options$ecotype_filename <- "WHCER048.ECO"
model_options$cultivar_filename <- "WHCER048.CUL"
model_options$ecotype <- "CAWH01"      # From SK0010 line
model_options$cultivar <- "SK0010"     # Sakha95
model_options$suppress_output <- TRUE

cat("  DSSAT path:", model_options$DSSAT_path, "\n")
cat("  Cultivar:", model_options$cultivar, "(Sakha95)\n")
cat("  Ecotype:", model_options$ecotype, "\n\n")

################################################################################
# STEP 4: LOAD FILTERED OBSERVED DATA
################################################################################

cat("Step 4: Loading filtered observed data...\n")

obs_file <- "C:/DSSAT48/data/Sakha95_observed_data_filtered.csv"
if (!file.exists(obs_file)) {
  stop("Filtered data not found! Run filter_data_simple.R first.")
}

obs_raw <- read.csv(obs_file, stringsAsFactors = FALSE)
obs_raw$Date <- as.Date(obs_raw$Date)

cat("  ✓ Loaded", nrow(obs_raw), "observations\n")

# Convert to CroptimizR format
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

cat("  ✓ Formatted", length(obs_list), "situations\n")
cat("  ✓ Variables:", paste(setdiff(names(obs_list[[1]]), "Date"), collapse = ", "), "\n\n")

################################################################################
# STEP 5: DEFINE PARAMETERS TO CALIBRATE
################################################################################

cat("Step 5: Defining parameters to calibrate...\n")

# Current SK0010 values from cultivar file:
# P1V: 16.0, P1D: 74.6, P5: 660, G1: 47.0, G2: 80, G3: 0.8, PHINT: 131.0

# Define bounds around these values
param_info <- list(
  lb = c(P1V = 0,       # Vernalization (current: 16.0)
         P1D = 50,      # Photoperiod (current: 74.6)
         P5 = 500,      # Grain filling (current: 660)
         G1 = 30,       # Kernel number (current: 47.0)
         G2 = 50,       # Kernel weight (current: 80)
         G3 = 0.5,      # Stem weight (current: 0.8)
         PHINT = 90),   # Phylochron (current: 131.0)
  
  ub = c(P1V = 45,
         P1D = 90,
         P5 = 800,
         G1 = 70,
         G2 = 120,
         G3 = 2.0,
         PHINT = 150)
)

cat("\n  Parameters to calibrate:\n")
cat("                 Current   Lower    Upper\n")
cat("    P1V          16.0      0.0      45.0\n")
cat("    P1D          74.6      50.0     90.0\n")
cat("    P5           660       500      800\n")
cat("    G1           47.0      30.0     70.0\n")
cat("    G2           80        50       120\n")
cat("    G3           0.8       0.5      2.0\n")
cat("    PHINT        131.0     90.0     150.0\n\n")

################################################################################
# STEP 6: RUN CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              STARTING CALIBRATION                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "Sakha95_calibration_results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

optim_options <- list(
  maxeval = 300,              # Reduced for testing
  xtol_rel = 1e-3,
  out_dir = output_dir,
  path_results = output_dir
)

cat("Calibration settings:\n")
cat("  Method: Nelder-Mead simplex\n")
cat("  Max evaluations:", optim_options$maxeval, "\n")
cat("  Situations:", length(situation_names), "\n")
cat("  Parameters:", length(param_info$lb), "\n")
cat("  Output:", output_dir, "\n\n")

cat("⚠ This will take 1-4 hours. Progress shown below:\n\n")

start_time <- Sys.time()

# Run calibration
calib_result <- tryCatch({
  estim_param(
    obs_list = obs_list,
    model_function = DSSAT_wrapper,
    model_options = model_options,
    optim_options = optim_options,
    param_info = param_info
  )
}, error = function(e) {
  cat("\n⚠ Calibration error:\n")
  cat("  ", as.character(e), "\n\n")
  return(NULL)
})

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

if (is.null(calib_result)) {
  cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║              CALIBRATION FAILED                              ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  cat("Please check error messages above.\n\n")
  cat("Common issues:\n")
  cat("  1. Experiment file problems - check ERROR.OUT\n")
  cat("  2. Weather file missing\n")
  cat("  3. Cultivar/ecotype mismatch\n\n")
  stop("Calibration failed. See messages above.")
}

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║           CALIBRATION COMPLETED SUCCESSFULLY!                ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Time elapsed:", round(elapsed, 1), "minutes\n\n")

################################################################################
# STEP 7: ANALYZE RESULTS
################################################################################

cat("Step 7: Analyzing results...\n\n")

# Extract results
calibrated_params <- calib_result$final_values

# Create results table
initial_values <- c(P1V = 16.0, P1D = 74.6, P5 = 660, 
                   G1 = 47.0, G2 = 80, G3 = 0.8, PHINT = 131.0)

param_table <- data.frame(
  Parameter = names(calibrated_params),
  Initial = initial_values[names(calibrated_params)],
  Lower = param_info$lb[names(calibrated_params)],
  Upper = param_info$ub[names(calibrated_params)],
  Calibrated = as.numeric(calibrated_params),
  stringsAsFactors = FALSE
)

param_table$Change <- param_table$Calibrated - param_table$Initial
param_table$Change_Pct <- round((param_table$Change / param_table$Initial) * 100, 1)

cat("═══════════════════════════════════════════════════════════════\n")
cat("            CALIBRATED PARAMETERS FOR SAKHA95                  \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

print(param_table, row.names = FALSE)

cat("\n═══════════════════════════════════════════════════════════════\n\n")

# Save results
param_file <- file.path(output_dir, "Sakha95_calibrated_parameters.csv")
write.csv(param_table, param_file, row.names = FALSE)

results_file <- file.path(output_dir, "calibration_complete.RData")
save(calib_result, param_table, obs_list, file = results_file)

cat("✓ Results saved:\n")
cat("  -", param_file, "\n")
cat("  -", results_file, "\n\n")

################################################################################
# STEP 8: GENERATE PLOTS
################################################################################

cat("Step 8: Generating visualizations...\n\n")

# Run simulations
sim_default <- DSSAT_wrapper(
  model_options = model_options,
  situation = situation_names
)

sim_calibrated <- DSSAT_wrapper(
  param_values = calibrated_params,
  model_options = model_options,
  situation = situation_names
)

# Dynamic plots
if (!sim_default$error && !sim_calibrated$error) {
  cat("  Creating plots...\n")
  
  p_dynamic <- plot(
    sim_default = sim_default$sim_list,
    sim_calibrated = sim_calibrated$sim_list,
    obs = obs_list,
    type = "dynamic"
  )
  
  save_plot_pdf(p_dynamic, out_dir = output_dir, file_name = "Dynamic_plots.pdf")
  cat("    ✓ Dynamic plots saved\n")
  
  # Scatter plots
  p_scatter <- plot(
    sim_default = sim_default$sim_list,
    sim_calibrated = sim_calibrated$sim_list,
    obs = obs_list,
    type = "scatter",
    all_situations = TRUE
  )
  
  save_plot_pdf(p_scatter, out_dir = output_dir, file_name = "Scatter_plots.pdf")
  cat("    ✓ Scatter plots saved\n")
  
  # Statistics
  stats <- summary(
    sim_default = sim_default$sim_list,
    sim_calibrated = sim_calibrated$sim_list,
    obs = obs_list,
    stats = c("R2", "RMSE", "nRMSE", "EF", "Bias")
  )
  
  stats_file <- file.path(output_dir, "statistics.csv")
  write.csv(stats, stats_file, row.names = FALSE)
  cat("    ✓ Statistics saved\n\n")
  
  # Print summary
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("              PERFORMANCE SUMMARY                              \n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  stats_summary <- stats %>%
    filter(group == "sim_calibrated") %>%
    select(variable, R2, nRMSE, Bias)
  
  print(stats_summary, row.names = FALSE)
  cat("\n═══════════════════════════════════════════════════════════════\n\n")
}

################################################################################
# FINAL SUMMARY
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                 CALIBRATION COMPLETE!                        ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Summary:\n")
cat("  ✓ Calibrated 7 parameters\n")
cat("  ✓ Used 56 situations (23 GMZA + 33 SIDS)\n")
cat("  ✓ Processed 209 observations\n")
cat("  ✓ Time:", round(elapsed, 1), "minutes\n\n")

cat("Output files in:", output_dir, "/\n")
cat("  • Sakha95_calibrated_parameters.csv\n")
cat("  • calibration_complete.RData\n")
cat("  • Dynamic_plots.pdf\n")
cat("  • Scatter_plots.pdf\n")
cat("  • statistics.csv\n\n")

cat("Next steps:\n")
cat("  1. Review parameter changes (should be 5-30%)\n")
cat("  2. Check R² > 0.7 for main variables\n")
cat("  3. Update WHCER048.CUL with calibrated values\n")
cat("  4. Validate on independent data\n\n")

cat("To update SK0010 in cultivar file, change:\n")
for (i in 1:nrow(param_table)) {
  cat(sprintf("  %-8s: %.2f → %.2f\n",
              param_table$Parameter[i],
              param_table$Initial[i],
              param_table$Calibrated[i]))
}

cat("\n═══════════════════════════════════════════════════════════════\n\n")

cat("🎉 Sakha95 calibration complete! 🌾\n\n")

################################################################################
# END
################################################################################

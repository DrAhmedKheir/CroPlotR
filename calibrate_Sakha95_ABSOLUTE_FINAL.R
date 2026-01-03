################################################################################
# SAKHA95 CALIBRATION - ABSOLUTELY FINAL VERSION
# GMZA: 23 treatments, SIDS: 27 treatments = 50 situations total
# Using: Sakha95_observed_data_FINAL.csv
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║     SAKHA95 CALIBRATION - FINAL (50 SITUATIONS)             ║\n")
cat("║     GMZA: 23 treatments | SIDS: 27 treatments               ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# STEP 1: LOAD PACKAGES
################################################################################

cat("Step 1: Loading packages...\n")

suppressPackageStartupMessages({
  library(CroptimizR)
  library(CroPlotR)
  library(dplyr)
  library(tidyr)
})

cat("✓ Packages loaded\n\n")

################################################################################
# STEP 2: SOURCE WRAPPER
################################################################################

cat("Step 2: Loading DSSAT wrapper...\n")

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

if (file.exists("DSSAT_wrapper.R")) {
  source("DSSAT_wrapper.R", verbose = FALSE)
} else if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
}

cat("✓ Wrapper loaded\n\n")

################################################################################
# STEP 3: MODEL OPTIONS
################################################################################

cat("Step 3: Configuring DSSAT...\n")

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

cat("  Cultivar: SK0010 (Sakha95)\n")
cat("  Ecotype: CAWH01\n\n")

################################################################################
# STEP 4: LOAD FINAL FILTERED DATA
################################################################################

cat("Step 4: Loading FINAL filtered data...\n")

obs_file <- "C:/DSSAT48/data/Sakha95_observed_data_FINAL.csv"

if (!file.exists(obs_file)) {
  cat("\n  ⚠ FINAL data file not found!\n")
  cat("    Run filter_data_FINAL.R first!\n\n")
  stop("Missing data file")
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

# Count by experiment
gmza_sits <- sum(grepl("GMZA", situation_names))
sids_sits <- sum(grepl("SIDS", situation_names))
cat("    - GMZA:", gmza_sits, "situations\n")
cat("    - SIDS:", sids_sits, "situations\n\n")

################################################################################
# STEP 5: DEFINE PARAMETERS
################################################################################

cat("Step 5: Parameter bounds...\n")

# Current SK0010: P1V=16, P1D=74.6, P5=660, G1=47, G2=80, G3=0.8, PHINT=131

param_info <- list(
  lb = c(P1V = 0, P1D = 50, P5 = 500, G1 = 30, G2 = 50, G3 = 0.5, PHINT = 90),
  ub = c(P1V = 45, P1D = 90, P5 = 800, G1 = 70, G2 = 120, G3 = 2.0, PHINT = 150)
)

cat("  Calibrating 7 parameters\n")
cat("  (P1V, P1D, P5, G1, G2, G3, PHINT)\n\n")

################################################################################
# STEP 6: CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              STARTING CALIBRATION                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "Sakha95_FINAL_results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

optim_options <- list(
  maxeval = 200,
  xtol_rel = 1e-3,
  out_dir = output_dir,
  path_results = output_dir
)

cat("Settings:\n")
cat("  Max evaluations:", optim_options$maxeval, "\n")
cat("  Situations:", length(situation_names), "\n")
cat("  Output:", output_dir, "\n\n")

cat("⏱ Starting... (expect 1-3 hours)\n\n")

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
  cat("\n❌ CALIBRATION ERROR:\n")
  cat("  ", as.character(e), "\n\n")
  return(NULL)
})

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

if (is.null(calib_result)) {
  cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║              CALIBRATION FAILED                              ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  stop("See error messages above")
}

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         CALIBRATION COMPLETED SUCCESSFULLY!                  ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Time:", round(elapsed, 1), "minutes\n\n")

################################################################################
# STEP 7: EXTRACT RESULTS
################################################################################

cat("Step 7: Extracting results...\n\n")

# Get final parameters
if (!is.null(calib_result$final_values)) {
  calibrated_params <- calib_result$final_values
  
  # Create table
  initial_vals <- c(P1V=16, P1D=74.6, P5=660, G1=47, G2=80, G3=0.8, PHINT=131)
  
  param_table <- data.frame(
    Parameter = names(calibrated_params),
    Initial = initial_vals[names(calibrated_params)],
    Calibrated = as.numeric(calibrated_params),
    stringsAsFactors = FALSE
  )
  
  param_table$Change <- param_table$Calibrated - param_table$Initial
  param_table$Change_Pct <- round(
    (param_table$Change / param_table$Initial) * 100, 1
  )
  
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("          CALIBRATED PARAMETERS FOR SAKHA95                    \n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  print(param_table, row.names = FALSE)
  
  cat("\n═══════════════════════════════════════════════════════════════\n\n")
  
  # Save
  param_file <- file.path(output_dir, "Sakha95_parameters.csv")
  write.csv(param_table, param_file, row.names = FALSE)
  
  results_file <- file.path(output_dir, "calibration.RData")
  save(calib_result, param_table, obs_list, file = results_file)
  
  cat("✓ Results saved:\n")
  cat("  ", param_file, "\n")
  cat("  ", results_file, "\n\n")
  
} else {
  cat("⚠ No final_values found in calibration result\n")
  cat("  Check:", file.path(output_dir, "optim_results.Rdata"), "\n\n")
}

################################################################################
# STEP 8: VISUALIZE (if successful)
################################################################################

if (!is.null(calib_result$final_values)) {
  cat("Step 8: Creating visualizations...\n\n")
  
  # Simulations
  sim_init <- DSSAT_wrapper(
    model_options = model_options,
    situation = situation_names
  )
  
  sim_final <- DSSAT_wrapper(
    param_values = calibrated_params,
    model_options = model_options,
    situation = situation_names
  )
  
  if (!sim_init$error && !sim_final$error) {
    
    # Dynamic plots
    p_dyn <- plot(
      Initial = sim_init$sim_list,
      Calibrated = sim_final$sim_list,
      obs = obs_list,
      type = "dynamic"
    )
    
    save_plot_pdf(p_dyn, out_dir = output_dir, 
                  file_name = "Dynamic_plots.pdf")
    cat("  ✓ Dynamic plots\n")
    
    # Scatter
    p_scat <- plot(
      Initial = sim_init$sim_list,
      Calibrated = sim_final$sim_list,
      obs = obs_list,
      type = "scatter",
      all_situations = TRUE
    )
    
    save_plot_pdf(p_scat, out_dir = output_dir,
                  file_name = "Scatter_plots.pdf")
    cat("  ✓ Scatter plots\n")
    
    # Statistics
    stats <- summary(
      Initial = sim_init$sim_list,
      Calibrated = sim_final$sim_list,
      obs = obs_list,
      stats = c("R2", "RMSE", "nRMSE", "EF", "Bias")
    )
    
    stats_file <- file.path(output_dir, "statistics.csv")
    write.csv(stats, stats_file, row.names = FALSE)
    cat("  ✓ Statistics\n\n")
    
    # Print stats
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("              PERFORMANCE SUMMARY                              \n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    stats_cal <- stats %>%
      filter(group == "Calibrated") %>%
      select(variable, R2, nRMSE, Bias)
    
    print(stats_cal, row.names = FALSE)
    
    cat("\n═══════════════════════════════════════════════════════════════\n\n")
  }
}

################################################################################
# FINAL SUMMARY
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                CALIBRATION COMPLETE!                         ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Summary:\n")
cat("  ✓ Calibrated: 7 parameters\n")
cat("  ✓ Situations: 50 (23 GMZA + 27 SIDS)\n")
cat("  ✓ Observations:", nrow(obs_raw), "\n")
cat("  ✓ Time:", round(elapsed, 1), "minutes\n\n")

cat("Output:", output_dir, "/\n\n")

if (!is.null(calib_result$final_values)) {
  cat("To update WHCER048.CUL, change SK0010 line:\n\n")
  for (i in 1:nrow(param_table)) {
    cat(sprintf("  %-8s: %6.1f → %6.1f (%.1f%%)\n",
                param_table$Parameter[i],
                param_table$Initial[i],
                param_table$Calibrated[i],
                param_table$Change_Pct[i]))
  }
}

cat("\n═══════════════════════════════════════════════════════════════\n\n")

cat("🎉 Done! 🌾\n\n")

################################################################################
# END
################################################################################

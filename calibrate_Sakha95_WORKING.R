################################################################################
# SAKHA95 CALIBRATION - WORKING VERSION WITH INITIAL VALUES
# Key fix: Provide explicit initial parameter values to optimizer
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  SAKHA95 CALIBRATION - WITH INITIAL VALUES (50 SITS)        ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# SETUP
################################################################################

cat("Loading packages and wrapper...\n")

suppressPackageStartupMessages({
  library(CroptimizR)
  library(CroPlotR)
  library(dplyr)
  library(tidyr)
})

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

if (file.exists("DSSAT_wrapper.R")) {
  source("DSSAT_wrapper.R", verbose = FALSE)
} else {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
}

cat("✓ Setup complete\n\n")

################################################################################
# CONFIGURATION
################################################################################

cat("Configuring...\n")

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

cat("  Situations:", length(obs_list), "\n")
cat("  Observations:", nrow(obs_raw), "\n\n")

################################################################################
# PARAMETERS WITH INITIAL VALUES
################################################################################

cat("Defining parameters...\n\n")

# Current SK0010 values: P1V=16, P1D=74.6, P5=660, G1=47, G2=80, G3=0.8, PHINT=131

# Define with init, lb, ub (CroptimizR format)
param_info <- list(
  init = c(P1V = 16,    # Start at current value
           P1D = 74.6,
           P5 = 660,
           G1 = 47,
           G2 = 80,
           G3 = 0.8,
           PHINT = 131),
  
  lb = c(P1V = 0,
         P1D = 50,
         P5 = 500,
         G1 = 30,
         G2 = 50,
         G3 = 0.5,
         PHINT = 90),
  
  ub = c(P1V = 45,
         P1D = 90,
         P5 = 800,
         G1 = 70,
         G2 = 120,
         G3 = 2.0,
         PHINT = 150)
)

cat("  Parameters (7):\n")
for (p in names(param_info$init)) {
  cat(sprintf("    %-8s: init=%6.1f  [%6.1f - %6.1f]\n",
              p, param_info$init[p], param_info$lb[p], param_info$ub[p]))
}
cat("\n")

################################################################################
# CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              STARTING CALIBRATION                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "Sakha95_WORKING_results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

optim_options <- list(
  nb_rep = 1,                    # Only 1 repetition
  maxeval = 100,                 # Reduced for testing
  xtol_rel = 1e-3,
  path_results = output_dir
)

cat("Settings:\n")
cat("  Method: Nelder-Mead simplex\n")
cat("  Max evaluations:", optim_options$maxeval, "\n")
cat("  Repetitions:", optim_options$nb_rep, "\n")
cat("  Situations:", length(situation_names), "\n\n")

cat("Starting... (1-2 hours)\n\n")

start_time <- Sys.time()

calib_result <- tryCatch({
  estim_param(
    obs_list = obs_list,
    model_function = DSSAT_wrapper,
    model_options = model_options,
    optim_options = optim_options,
    param_info = param_info  # Now includes init, lb, ub
  )
}, error = function(e) {
  cat("\n❌ ERROR:\n")
  cat("  ", as.character(e), "\n\n")
  return(NULL)
})

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

################################################################################
# RESULTS
################################################################################

if (is.null(calib_result)) {
  cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║              CALIBRATION FAILED                              ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  # Check for partial results
  if (file.exists(file.path(output_dir, "optim_results.Rdata"))) {
    cat("Partial results saved in:", output_dir, "\n")
    cat("Check optim_results.Rdata for details\n\n")
  }
  
  stop("Calibration failed")
}

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         CALIBRATION COMPLETED!                               ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Time:", round(elapsed, 1), "minutes\n\n")

################################################################################
# EXTRACT AND DISPLAY RESULTS
################################################################################

cat("Extracting results...\n\n")

if (!is.null(calib_result$final_values)) {
  
  calibrated_params <- calib_result$final_values
  
  # Create comparison table
  param_table <- data.frame(
    Parameter = names(calibrated_params),
    Initial = param_info$init[names(calibrated_params)],
    Lower = param_info$lb[names(calibrated_params)],
    Upper = param_info$ub[names(calibrated_params)],
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
  
  # Save results
  param_file <- file.path(output_dir, "Sakha95_calibrated_parameters.csv")
  write.csv(param_table, param_file, row.names = FALSE)
  
  results_file <- file.path(output_dir, "calibration_complete.RData")
  save(calib_result, param_table, obs_list, file = results_file)
  
  cat("✓ Results saved:\n")
  cat("  ", param_file, "\n")
  cat("  ", results_file, "\n\n")
  
  # Show optimization info
  if (!is.null(calib_result$ind_min_crit)) {
    cat("Optimization info:\n")
    cat("  Best iteration:", calib_result$ind_min_crit, "\n")
    cat("  Final criterion:", round(calib_result$min_crit_value, 4), "\n")
    cat("  Evaluations:", length(calib_result$ind_min_crit), "\n\n")
  }
  
} else {
  cat("⚠ No final_values in result\n\n")
}

################################################################################
# CREATE VISUALIZATIONS
################################################################################

if (!is.null(calib_result$final_values)) {
  
  cat("Creating visualizations...\n\n")
  
  # Run simulations
  cat("  Running initial simulation...\n")
  sim_init <- DSSAT_wrapper(
    param_values = param_info$init,
    model_options = model_options,
    situation = situation_names
  )
  
  cat("  Running calibrated simulation...\n")
  sim_calib <- DSSAT_wrapper(
    param_values = calibrated_params,
    model_options = model_options,
    situation = situation_names
  )
  
  if (!sim_init$error && !sim_calib$error) {
    
    cat("  Generating plots...\n")
    
    # Dynamic plots
    p_dyn <- plot(
      Initial = sim_init$sim_list,
      Calibrated = sim_calib$sim_list,
      obs = obs_list,
      type = "dynamic"
    )
    
    save_plot_pdf(p_dyn, out_dir = output_dir, 
                  file_name = "Dynamic_plots.pdf")
    
    # Scatter plots
    p_scat <- plot(
      Initial = sim_init$sim_list,
      Calibrated = sim_calib$sim_list,
      obs = obs_list,
      type = "scatter",
      all_situations = TRUE
    )
    
    save_plot_pdf(p_scat, out_dir = output_dir,
                  file_name = "Scatter_plots.pdf")
    
    # Statistics
    stats <- summary(
      Initial = sim_init$sim_list,
      Calibrated = sim_calib$sim_list,
      obs = obs_list,
      stats = c("R2", "RMSE", "nRMSE", "EF", "Bias", "MAE")
    )
    
    stats_file <- file.path(output_dir, "statistics.csv")
    write.csv(stats, stats_file, row.names = FALSE)
    
    cat("  ✓ Plots and statistics saved\n\n")
    
    # Display statistics
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("              PERFORMANCE SUMMARY                              \n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    stats_calib <- stats %>%
      filter(group == "Calibrated") %>%
      select(variable, R2, nRMSE, Bias, MAE)
    
    print(stats_calib, row.names = FALSE)
    
    cat("\n═══════════════════════════════════════════════════════════════\n\n")
  }
}

################################################################################
# SUMMARY
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                     SUMMARY                                  ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Calibration:\n")
cat("  ✓ Parameters: 7\n")
cat("  ✓ Situations: 50 (23 GMZA + 27 SIDS)\n")
cat("  ✓ Observations: 185\n")
cat("  ✓ Time:", round(elapsed, 1), "minutes\n\n")

cat("Output:", output_dir, "/\n")
cat("  • Sakha95_calibrated_parameters.csv\n")
cat("  • calibration_complete.RData\n")
cat("  • Dynamic_plots.pdf\n")
cat("  • Scatter_plots.pdf\n")
cat("  • statistics.csv\n\n")

if (!is.null(calib_result$final_values)) {
  cat("To update WHCER048.CUL (SK0010 line):\n\n")
  for (i in 1:nrow(param_table)) {
    cat(sprintf("  %-8s: %6.1f → %6.1f (%+.1f%%)\n",
                param_table$Parameter[i],
                param_table$Initial[i],
                param_table$Calibrated[i],
                param_table$Change_Pct[i]))
  }
}

cat("\n═══════════════════════════════════════════════════════════════\n\n")

cat("🎉 DONE! 🌾\n\n")

################################################################################
# END
################################################################################

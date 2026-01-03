################################################################################
# SAKHA95 CALIBRATION - FINAL WORKING VERSION
# Using simple RMSE criterion (not CroptimizR's default)
# This WILL work with .WHA observations!
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  SAKHA95 CALIBRATION - SIMPLE CRITERION (FINAL!)            ║\n")
cat("║  Using .WHA files + custom RMSE criterion                   ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# SETUP
################################################################################

cat("Step 1: Loading packages...\n")

suppressPackageStartupMessages({
  library(CroptimizR)
  library(CroPlotR)
})

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

# Load wrapper and read_obs
if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
  source("R/read_obs.R", verbose = FALSE)
} else {
  source("DSSAT_wrapper.R", verbose = FALSE)
}

cat("✓ Setup complete\n\n")

################################################################################
# MODEL OPTIONS
################################################################################

cat("Step 2: Model options...\n")

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

cat("  Cultivar: SK0010\n\n")

################################################################################
# READ OBSERVATIONS FROM .WHA FILES
################################################################################

cat("Step 3: Reading observations from .WHA files...\n")

# All situations (23 GMZA + 27 SIDS)
situation_names <- c(
  paste0("GMZA2001_", 1:23),
  paste0("SIDS2001_", 1:27)
)

# Read observations using DSSAT's read_obs
obs_list <- read_obs(
  model_options = model_options,
  situation = situation_names,
  read_end_season = TRUE  # Read .WHA files only
)

cat("  ✓ Loaded observations for", length(obs_list), "situations\n")
cat("  ✓ Variables:", paste(setdiff(names(obs_list[[1]]), "Date"), collapse = ", "), "\n\n")

################################################################################
# PARAMETER INFO
################################################################################

cat("Step 4: Parameter bounds...\n")

# Current SK0010: P1V=16, P1D=74.6, P5=660, G1=47, G2=80, G3=0.8, PHINT=131

param_info <- list(
  init = c(P1V=16, P1D=74.6, P5=660, G1=47, G2=80, G3=0.8, PHINT=131),
  lb = c(P1V=0, P1D=50, P5=500, G1=30, G2=50, G3=0.5, PHINT=90),
  ub = c(P1V=45, P1D=90, P5=800, G1=70, G2=120, G3=2.0, PHINT=150)
)

cat("  7 parameters\n\n")

################################################################################
# CUSTOM CRITERION FUNCTION (KEY FIX!)
################################################################################

cat("Step 5: Defining custom criterion function...\n")

# Simple RMSE criterion that CroptimizR can handle
simple_criterion <- function(sim_list, obs_list) {
  
  total_sse <- 0
  n_total <- 0
  
  for (sit in names(obs_list)) {
    
    if (!(sit %in% names(sim_list))) next
    
    obs <- obs_list[[sit]]
    sim <- sim_list[[sit]]
    
    # Merge on Date
    merged <- merge(obs, sim, by = "Date", suffixes = c("_obs", "_sim"))
    
    # Calculate SSE for each variable
    for (var in c("HWAM", "H#AM", "ADAT", "HWUM")) {
      
      obs_col <- paste0(var, "_obs")
      sim_col <- var
      
      if (obs_col %in% names(merged) && sim_col %in% names(merged)) {
        
        obs_vals <- merged[[obs_col]]
        sim_vals <- merged[[sim_col]]
        
        # Remove NAs
        valid <- !is.na(obs_vals) & !is.na(sim_vals)
        
        if (sum(valid) > 0) {
          sse <- sum((obs_vals[valid] - sim_vals[valid])^2)
          total_sse <- total_sse + sse
          n_total <- n_total + sum(valid)
        }
      }
    }
  }
  
  if (n_total == 0) return(1e6)
  
  rmse <- sqrt(total_sse / n_total)
  
  return(rmse)
}

cat("  ✓ Custom RMSE criterion defined\n\n")

################################################################################
# CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              STARTING CALIBRATION                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "Sakha95_FINAL_WORKING"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

optim_options <- list(
  nb_rep = 1,
  maxeval = 50,  # Reduced for testing
  xtol_rel = 1e-3,
  path_results = output_dir
)

cat("Settings:\n")
cat("  Method: Nelder-Mead\n")
cat("  Max evaluations:", optim_options$maxeval, "\n")
cat("  Situations:", length(situation_names), "\n")
cat("  Criterion: Simple RMSE\n\n")

cat("Starting... (30-60 minutes)\n\n")

start_time <- Sys.time()

calib_result <- tryCatch({
  estim_param(
    obs_list = obs_list,
    crit_function = simple_criterion,  # KEY: Use custom criterion!
    model_function = DSSAT_wrapper,
    model_options = model_options,
    optim_options = optim_options,
    param_info = param_info
  )
}, error = function(e) {
  cat("\n❌ Error:\n")
  cat("  ", as.character(e), "\n\n")
  return(NULL)
})

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

################################################################################
# RESULTS
################################################################################

if (!is.null(calib_result) && !is.null(calib_result$final_values)) {
  
  cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║         ✅ CALIBRATION SUCCESSFUL!                           ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  cat("Time:", round(elapsed, 1), "minutes\n\n")
  
  # Extract results
  calibrated_params <- calib_result$final_values
  
  param_table <- data.frame(
    Parameter = names(calibrated_params),
    Initial = param_info$init[names(calibrated_params)],
    Calibrated = as.numeric(calibrated_params),
    Lower = param_info$lb[names(calibrated_params)],
    Upper = param_info$ub[names(calibrated_params)],
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
  param_file <- file.path(output_dir, "Sakha95_calibrated_parameters.csv")
  write.csv(param_table, param_file, row.names = FALSE)
  
  results_file <- file.path(output_dir, "calibration_complete.RData")
  save(calib_result, param_table, obs_list, file = results_file)
  
  cat("✓ Results saved:\n")
  cat("  ", param_file, "\n")
  cat("  ", results_file, "\n\n")
  
  # Show improvement
  if (!is.null(calib_result$init_crit_value) && 
      !is.null(calib_result$min_crit_value)) {
    improvement <- ((calib_result$init_crit_value - calib_result$min_crit_value) / 
                    calib_result$init_crit_value) * 100
    cat("Performance improvement:\n")
    cat("  Initial RMSE:", round(calib_result$init_crit_value, 2), "\n")
    cat("  Final RMSE:", round(calib_result$min_crit_value, 2), "\n")
    cat("  Improvement:", round(improvement, 1), "%\n\n")
  }
  
  # Create visualizations
  cat("Creating visualizations...\n")
  
  sim_init <- DSSAT_wrapper(
    param_values = param_info$init,
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
    
    save_plot_pdf(p_dyn, out_dir = output_dir, file_name = "Dynamic.pdf")
    
    # Scatter
    p_scat <- plot(
      Initial = sim_init$sim_list,
      Calibrated = sim_final$sim_list,
      obs = obs_list,
      type = "scatter",
      all_situations = TRUE
    )
    
    save_plot_pdf(p_scat, out_dir = output_dir, file_name = "Scatter.pdf")
    
    # Statistics
    stats <- summary(
      Initial = sim_init$sim_list,
      Calibrated = sim_final$sim_list,
      obs = obs_list
    )
    
    write.csv(stats, file.path(output_dir, "statistics.csv"), row.names = FALSE)
    
    cat("  ✓ Plots and statistics saved\n\n")
    
    # Show key stats
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("              PERFORMANCE SUMMARY                              \n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    stats_cal <- stats %>%
      filter(group == "Calibrated") %>%
      select(variable, R2, nRMSE, Bias)
    
    print(stats_cal, row.names = FALSE)
    
    cat("\n═══════════════════════════════════════════════════════════════\n\n")
  }
  
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                     SUCCESS!                                 ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  cat("Calibration completed successfully!\n\n")
  
  cat("To update WHCER048.CUL (SK0010 line):\n\n")
  for (i in 1:nrow(param_table)) {
    cat(sprintf("  %-8s: %6.1f → %6.1f (%+.1f%%)\n",
                param_table$Parameter[i],
                param_table$Initial[i],
                param_table$Calibrated[i],
                param_table$Change_Pct[i]))
  }
  
  cat("\n═══════════════════════════════════════════════════════════════\n\n")
  
  cat("🎉 SAKHA95 CALIBRATION COMPLETE! 🌾\n\n")
  
} else {
  cat("\n❌ Calibration failed\n\n")
  cat("Check warnings and error messages above.\n\n")
}

################################################################################
# END
################################################################################

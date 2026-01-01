#!/usr/bin/env Rscript

################################################################################
# DSSAT-R Interface Helper Functions
# 
# This script provides helper functions for interfacing with DSSAT
# when direct DSSAT-R package is not available
#
# Author: Generated for DSSAT calibration
# Date: 2026-01-01
################################################################################

#' Write DSSAT Batch File
#'
#' Creates a DSSAT batch file for running simulations
#'
#' @param batch_file Path to output batch file
#' @param experiment_files Vector of experiment file paths
#' @param model Crop model code (e.g., "MZCER048")
#' @return Path to created batch file
write_dssat_batch <- function(batch_file, experiment_files, model = "MZCER048") {
  
  batch_content <- c(
    "$BATCH(DSSAT Calibration Batch)",
    "!",
    "! Batch file for DSSAT calibration",
    paste0("! Generated: ", Sys.time()),
    "!",
    "@FILEX                                                                                        TRTNO     RP     SQ     OP     CO",
    ""
  )
  
  for (i in seq_along(experiment_files)) {
    exp_file <- basename(experiment_files[i])
    batch_content <- c(
      batch_content,
      sprintf("%-92s %5d %5d %5d %5d %5d", exp_file, i, 1, 0, 0, 0)
    )
  }
  
  writeLines(batch_content, batch_file)
  
  return(batch_file)
}

#' Read DSSAT Summary Output
#'
#' Reads DSSAT Summary.OUT file and extracts key variables
#'
#' @param summary_file Path to Summary.OUT file
#' @return Data frame with simulation results
read_dssat_summary <- function(summary_file) {
  
  if (!file.exists(summary_file)) {
    warning("Summary file not found: ", summary_file)
    return(NULL)
  }
  
  # Read the file
  lines <- readLines(summary_file)
  
  # Find header line (starts with @)
  header_idx <- grep("^@", lines)[1]
  
  if (is.na(header_idx)) {
    warning("Could not find header in summary file")
    return(NULL)
  }
  
  # Extract header and data
  header <- lines[header_idx]
  data_lines <- lines[(header_idx + 1):length(lines)]
  data_lines <- data_lines[nchar(trimws(data_lines)) > 0]  # Remove empty lines
  
  # Parse header
  header <- gsub("@", "", header)
  col_names <- strsplit(trimws(header), "\\s+")[[1]]
  
  # Parse data
  data_list <- lapply(data_lines, function(line) {
    strsplit(trimws(line), "\\s+")[[1]]
  })
  
  # Convert to data frame
  df <- do.call(rbind, lapply(data_list, function(x) {
    as.data.frame(t(x), stringsAsFactors = FALSE)
  }))
  
  colnames(df) <- col_names[1:ncol(df)]
  
  # Convert numeric columns
  numeric_cols <- c("HWAM", "CWAM", "LAIX", "GNAM", "CNAM", "ADAT", "MDAT", 
                    "HWUM", "H#AM", "EDAT", "TDAT")
  
  for (col in numeric_cols) {
    if (col %in% colnames(df)) {
      df[[col]] <- as.numeric(df[[col]])
    }
  }
  
  return(df)
}

#' Read DSSAT PlantGro Output
#'
#' Reads DSSAT PlantGro.OUT file for time series data
#'
#' @param plantgro_file Path to PlantGro.OUT file
#' @return Data frame with daily simulation results
read_dssat_plantgro <- function(plantgro_file) {
  
  if (!file.exists(plantgro_file)) {
    warning("PlantGro file not found: ", plantgro_file)
    return(NULL)
  }
  
  # Read the file
  lines <- readLines(plantgro_file)
  
  # Find header line
  header_idx <- grep("^@", lines)[1]
  
  if (is.na(header_idx)) {
    warning("Could not find header in plantgro file")
    return(NULL)
  }
  
  # Extract header
  header <- lines[header_idx]
  header <- gsub("@", "", header)
  col_names <- strsplit(trimws(header), "\\s+")[[1]]
  
  # Extract data
  data_lines <- lines[(header_idx + 1):length(lines)]
  data_lines <- data_lines[nchar(trimws(data_lines)) > 0]
  
  # Parse data
  data_list <- lapply(data_lines, function(line) {
    strsplit(trimws(line), "\\s+")[[1]]
  })
  
  # Convert to data frame
  df <- do.call(rbind, lapply(data_list, function(x) {
    as.data.frame(t(x), stringsAsFactors = FALSE)
  }))
  
  colnames(df) <- col_names[1:ncol(df)]
  
  # Convert numeric columns
  numeric_cols <- setdiff(col_names, c("YEAR", "DOY", "DAS", "DATE"))
  
  for (col in numeric_cols) {
    if (col %in% colnames(df)) {
      df[[col]] <- as.numeric(df[[col]])
    }
  }
  
  # Convert date if present
  if ("DATE" %in% colnames(df)) {
    df$Date <- as.Date(df$DATE, format = "%y%j")
  }
  
  return(df)
}

#' Update DSSAT Cultivar File
#'
#' Updates cultivar genetic coefficients in DSSAT .CUL file
#'
#' @param cul_file Path to cultivar file
#' @param cultivar_name Name of cultivar to update
#' @param parameters Named vector of parameter values
#' @return TRUE if successful
update_dssat_cultivar <- function(cul_file, cultivar_name, parameters) {
  
  if (!file.exists(cul_file)) {
    warning("Cultivar file not found: ", cul_file)
    return(FALSE)
  }
  
  # Read file
  lines <- readLines(cul_file)
  
  # Find cultivar line
  cultivar_idx <- grep(cultivar_name, lines, fixed = TRUE)
  
  if (length(cultivar_idx) == 0) {
    warning("Cultivar not found in file: ", cultivar_name)
    return(FALSE)
  }
  
  # Get the cultivar line
  cultivar_line <- lines[cultivar_idx[1]]
  
  # Update parameters (this is model-specific and may need adjustment)
  # Example format for CERES-Maize: P1, P2, P5, G2, G3, PHINT
  
  # Parse existing line
  parts <- strsplit(cultivar_line, "\\s+")[[1]]
  
  # Update parameter values (adjust indices based on file format)
  # This is a simplified example - actual implementation depends on file format
  for (param_name in names(parameters)) {
    # Find and update parameter value
    # Implementation depends on specific .CUL file format
  }
  
  # Write updated line back
  lines[cultivar_idx[1]] <- cultivar_line
  
  # Write file
  writeLines(lines, cul_file)
  
  message("Updated cultivar: ", cultivar_name)
  
  return(TRUE)
}

#' Run DSSAT via System Call
#'
#' Executes DSSAT model using system command
#'
#' @param dssat_dir DSSAT installation directory
#' @param work_dir Working directory containing input files
#' @param model Model code (e.g., "MZCER048")
#' @return Exit code from DSSAT
run_dssat_system <- function(dssat_dir, work_dir, model = "MZCER048") {
  
  # DSSAT executable
  dssat_exe <- file.path(dssat_dir, "DSCSM048.EXE")
  
  if (!file.exists(dssat_exe)) {
    # Try alternative names
    alt_names <- c("DSCSM047.EXE", "dscsm048", "dscsm047")
    for (alt_name in alt_names) {
      alt_path <- file.path(dssat_dir, alt_name)
      if (file.exists(alt_path)) {
        dssat_exe <- alt_path
        break
      }
    }
  }
  
  if (!file.exists(dssat_exe)) {
    stop("DSSAT executable not found in: ", dssat_dir)
  }
  
  # Build command
  if (.Platform$OS.type == "windows") {
    cmd <- sprintf('cd "%s" && "%s" A %s B DSSBatch.v48', work_dir, dssat_exe, model)
  } else {
    cmd <- sprintf('cd "%s" && "%s" A %s B DSSBatch.v48', work_dir, dssat_exe, model)
  }
  
  # Run DSSAT
  result <- system(cmd, intern = FALSE)
  
  return(result)
}

#' Convert Parameter Vector to DSSAT Format
#'
#' Converts parameter values to DSSAT cultivar coefficient format
#'
#' @param params Named vector of parameters
#' @param model Crop model code
#' @return Formatted string for cultivar file
format_cultivar_coefficients <- function(params, model = "MZCER048") {
  
  # Format depends on crop model
  if (grepl("^MZ", model)) {
    # CERES-Maize format
    coef_string <- sprintf(
      "%6.1f %6.3f %6.1f %6.0f %6.2f %6.1f",
      params["P1"], params["P2"], params["P5"],
      params["G2"], params["G3"], params["PHINT"]
    )
  } else if (grepl("^WH", model)) {
    # CERES-Wheat format
    coef_string <- sprintf(
      "%6.1f %6.1f %6.1f %6.1f %6.1f %6.2f %6.1f",
      params["P1V"], params["P1D"], params["P5"],
      params["G1"], params["G2"], params["G3"], params["PHINT"]
    )
  } else {
    # Generic format
    coef_string <- paste(sprintf("%6.2f", params), collapse = " ")
  }
  
  return(coef_string)
}

#' Validate DSSAT Input Files
#'
#' Checks that required DSSAT input files exist and are valid
#'
#' @param work_dir Working directory
#' @param experiment_file Experiment file name
#' @return List of validation results
validate_dssat_inputs <- function(work_dir, experiment_file) {
  
  results <- list(
    valid = TRUE,
    messages = character(0),
    warnings = character(0),
    errors = character(0)
  )
  
  # Check experiment file
  exp_path <- file.path(work_dir, experiment_file)
  if (!file.exists(exp_path)) {
    results$errors <- c(results$errors, paste("Experiment file not found:", experiment_file))
    results$valid <- FALSE
  } else {
    results$messages <- c(results$messages, "Experiment file found")
  }
  
  # Check for weather file reference in experiment file
  if (file.exists(exp_path)) {
    exp_content <- readLines(exp_path)
    wth_line <- grep("@WSTA", exp_content, value = TRUE)
    
    if (length(wth_line) > 0) {
      results$messages <- c(results$messages, "Weather file reference found")
    } else {
      results$warnings <- c(results$warnings, "Weather file reference not found in experiment file")
    }
  }
  
  # Check for soil file
  soil_files <- list.files(work_dir, pattern = "\\.SOL$", ignore.case = TRUE)
  if (length(soil_files) > 0) {
    results$messages <- c(results$messages, paste("Soil file found:", soil_files[1]))
  } else {
    results$warnings <- c(results$warnings, "No soil file (.SOL) found")
  }
  
  # Check for cultivar file
  cul_files <- list.files(work_dir, pattern = "\\.CUL$", ignore.case = TRUE)
  if (length(cul_files) > 0) {
    results$messages <- c(results$messages, paste("Cultivar file found:", cul_files[1]))
  } else {
    results$warnings <- c(results$warnings, "No cultivar file (.CUL) found")
  }
  
  # Print results
  if (length(results$messages) > 0) {
    cat("\nValidation Messages:\n")
    cat(paste("  [OK]", results$messages), sep = "\n")
  }
  
  if (length(results$warnings) > 0) {
    cat("\nValidation Warnings:\n")
    cat(paste("  [WARNING]", results$warnings), sep = "\n")
  }
  
  if (length(results$errors) > 0) {
    cat("\nValidation Errors:\n")
    cat(paste("  [ERROR]", results$errors), sep = "\n")
  }
  
  return(results)
}

# Export functions
if (!interactive()) {
  message("DSSAT-R helper functions loaded.")
  message("Available functions:")
  message("  - write_dssat_batch()")
  message("  - read_dssat_summary()")
  message("  - read_dssat_plantgro()")
  message("  - update_dssat_cultivar()")
  message("  - run_dssat_system()")
  message("  - format_cultivar_coefficients()")
  message("  - validate_dssat_inputs()")
}

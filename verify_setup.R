#!/usr/bin/env Rscript

################################################################################
# DSSAT Calibration Setup Verification Script
#
# This script checks that all components are properly installed and configured
# Run this before attempting calibration to identify any issues
#
# Usage: Rscript verify_setup.R
################################################################################

cat("\n")
cat("================================================================================\n")
cat("DSSAT CALIBRATION SETUP VERIFICATION\n")
cat("================================================================================\n\n")

# Track issues
issues <- character(0)
warnings <- character(0)
success_count <- 0
total_checks <- 0

check <- function(description, test_expr, critical = TRUE) {
  total_checks <<- total_checks + 1
  cat(sprintf("[%02d] Checking: %s\n", total_checks, description))
  
  result <- tryCatch({
    test_expr
    TRUE
  }, error = function(e) {
    if (critical) {
      issues <<- c(issues, paste(description, "-", e$message))
    } else {
      warnings <<- c(warnings, paste(description, "-", e$message))
    }
    FALSE
  })
  
  if (result) {
    cat("     ✓ PASS\n")
    success_count <<- success_count + 1
  } else {
    if (critical) {
      cat("     ✗ FAIL (Critical)\n")
    } else {
      cat("     ⚠ WARNING (Non-critical)\n")
    }
  }
  
  cat("\n")
  return(result)
}

# Check R version
check("R version >= 4.0", {
  r_version <- as.numeric(paste(R.version$major, R.version$minor, sep = "."))
  if (r_version < 4.0) {
    stop("R version is ", r_version, " but >= 4.0 required")
  }
  cat("     R version:", r_version, "\n")
})

# Check required packages
required_packages <- c("dplyr", "tidyr", "ggplot2")

for (pkg in required_packages) {
  check(paste("Package:", pkg), {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      stop(pkg, " package not installed")
    }
    pkg_version <- packageVersion(pkg)
    cat("     Version:", as.character(pkg_version), "\n")
  })
}

# Check CroPlotR
check("Package: CroPlotR", {
  if (!require("CroPlotR", quietly = TRUE)) {
    stop("CroPlotR package not installed. Install with: remotes::install_github('SticsRPacks/CroPlotR@*release')")
  }
  pkg_version <- packageVersion("CroPlotR")
  cat("     Version:", as.character(pkg_version), "\n")
})

# Check calibration scripts exist
scripts <- c(
  "calibrate_dssat.R",
  "calibration_config.R",
  "dssat_helpers.R",
  "example_calibration.R"
)

for (script in scripts) {
  check(paste("Script file:", script), {
    if (!file.exists(script)) {
      stop(script, " not found in current directory")
    }
    file_size <- file.info(script)$size
    cat("     Size:", format(file_size, big.mark = ","), "bytes\n")
  })
}

# Check documentation exists
docs <- c(
  "QUICK_START.md",
  "DSSAT_CALIBRATION_README.md",
  "FILE_SUMMARY.md",
  "README_CALIBRATION.md"
)

for (doc in docs) {
  check(paste("Documentation:", doc), {
    if (!file.exists(doc)) {
      stop(doc, " not found")
    }
  }, critical = FALSE)
}

# Check data directory
check("Data directory exists", {
  if (!dir.exists("data")) {
    stop("data/ directory not found")
  }
})

# Check for observed data template
check("Example data file", {
  obs_file <- "data/observed_data.csv"
  if (!file.exists(obs_file)) {
    stop("data/observed_data.csv not found")
  }
  obs_data <- read.csv(obs_file)
  cat("     Rows:", nrow(obs_data), "\n")
  cat("     Columns:", paste(names(obs_data), collapse = ", "), "\n")
  
  required_cols <- c("Experiment", "Treatment", "Date", "Variable", "Value")
  missing_cols <- setdiff(required_cols, names(obs_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
}, critical = FALSE)

# Check DSSAT directory (non-critical)
check("DSSAT installation directory", {
  dssat_dir <- Sys.getenv("DSSAT_DIR", "")
  if (dssat_dir == "") {
    dssat_dir <- "/opt/dssat"  # Default
  }
  
  if (!dir.exists(dssat_dir)) {
    stop("DSSAT directory not found at: ", dssat_dir, 
         "\nSet DSSAT_DIR environment variable or edit calibration_config.R")
  }
  
  cat("     Path:", dssat_dir, "\n")
  
  # Look for DSSAT executable
  dssat_exe <- list.files(dssat_dir, pattern = "DSCSM.*\\.EXE$|dscsm", 
                          ignore.case = TRUE, full.names = TRUE)
  if (length(dssat_exe) > 0) {
    cat("     Executable found:", basename(dssat_exe[1]), "\n")
  } else {
    cat("     WARNING: DSSAT executable not found\n")
  }
}, critical = FALSE)

# Check script syntax by sourcing helper functions
check("dssat_helpers.R syntax", {
  source("dssat_helpers.R", local = TRUE)
  cat("     Functions loaded successfully\n")
}, critical = FALSE)

# Check output directory can be created
check("Output directory creation", {
  test_dir <- "test_calibration_output"
  dir.create(test_dir, showWarnings = FALSE)
  if (!dir.exists(test_dir)) {
    stop("Cannot create output directory")
  }
  unlink(test_dir, recursive = TRUE)
  cat("     Output directory can be created\n")
})

# Summary
cat("\n")
cat("================================================================================\n")
cat("VERIFICATION SUMMARY\n")
cat("================================================================================\n\n")

cat(sprintf("Total Checks: %d\n", total_checks))
cat(sprintf("Passed: %d\n", success_count))
cat(sprintf("Failed: %d\n", length(issues)))
cat(sprintf("Warnings: %d\n", length(warnings)))
cat("\n")

if (length(issues) > 0) {
  cat("❌ CRITICAL ISSUES FOUND:\n\n")
  for (i in seq_along(issues)) {
    cat(sprintf("  %d. %s\n", i, issues[i]))
  }
  cat("\n")
  cat("Please resolve these issues before running calibration.\n\n")
}

if (length(warnings) > 0) {
  cat("⚠️  WARNINGS (Non-critical):\n\n")
  for (i in seq_along(warnings)) {
    cat(sprintf("  %d. %s\n", i, warnings[i]))
  }
  cat("\n")
  cat("These warnings may not prevent calibration but should be addressed.\n\n")
}

if (length(issues) == 0) {
  cat("✅ VERIFICATION PASSED!\n\n")
  cat("Your system is ready for DSSAT calibration.\n\n")
  cat("Next Steps:\n")
  cat("  1. Prepare your observed data in data/observed_data.csv\n")
  cat("  2. Configure settings in calibration_config.R\n")
  cat("  3. Run: source('calibration_config.R'); source('calibrate_dssat.R'); main()\n")
  cat("  4. Or try the tutorial: source('example_calibration.R')\n\n")
  
  cat("Quick Commands:\n")
  cat("  • Tutorial:     source('example_calibration.R')\n")
  cat("  • Quick Start:  See QUICK_START.md\n")
  cat("  • Full Guide:   See DSSAT_CALIBRATION_README.md\n")
  cat("\n")
} else {
  cat("❌ VERIFICATION FAILED\n\n")
  cat("Please address the critical issues above before proceeding.\n")
  cat("Refer to QUICK_START.md or DSSAT_CALIBRATION_README.md for help.\n\n")
}

cat("================================================================================\n\n")

# Return status
if (length(issues) == 0) {
  invisible(TRUE)
} else {
  invisible(FALSE)
}

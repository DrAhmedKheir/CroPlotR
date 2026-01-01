#!/usr/bin/env Rscript

################################################################################
# SAKHA95 CALIBRATION - SETUP VERIFICATION TEST
# Run this first to verify your setup before running the full calibration
################################################################################

cat("\n\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                                                               ║\n")
cat("║        SAKHA95 CALIBRATION - SETUP TEST                      ║\n")
cat("║                                                               ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# Function to get script directory
get_script_path <- function() {
  # Method 1: Command line args
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg)
    return(dirname(normalizePath(script_path, winslash = "/")))
  }
  
  # Method 2: RStudio
  if (requireNamespace("rstudioapi", quietly = TRUE)) {
    if (rstudioapi::isAvailable()) {
      tryCatch({
        return(dirname(rstudioapi::getSourceEditorContext()$path))
      }, error = function(e) {})
    }
  }
  
  # Method 3: Current directory
  return(getwd())
}

# Configuration
DSSAT_DIR <- "C:/DSSAT48"
WORK_DIR <- get_script_path()
DATA_DIR <- file.path(WORK_DIR, "data")

cat("═══════════════════════════════════════════════════════════════\n")
cat("CHECKING DIRECTORIES\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Check working directory
message("Script directory: ", WORK_DIR)
if (dir.exists(WORK_DIR)) {
  message("  ✓ Directory exists")
} else {
  message("  ✗ Directory does not exist")
}

# Check data directory
message("\nData directory: ", DATA_DIR)
if (dir.exists(DATA_DIR)) {
  message("  ✓ Directory exists")
} else {
  message("  ✗ Directory does NOT exist")
  message("  → Please create: ", DATA_DIR)
}

# Check DSSAT directory
message("\nDSSAT directory: ", DSSAT_DIR)
if (dir.exists(DSSAT_DIR)) {
  message("  ✓ Directory exists")
} else {
  message("  ✗ Directory does NOT exist")
  message("  → Please verify DSSAT installation")
}

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("CHECKING DSSAT FILES\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Check genotype files
genotype_dir <- file.path(DSSAT_DIR, "Genotype")
message("Genotype directory: ", genotype_dir)
if (dir.exists(genotype_dir)) {
  message("  ✓ Exists")
  
  # Check CUL file
  cul_file <- file.path(genotype_dir, "WHCER048.CUL")
  if (file.exists(cul_file)) {
    message("  ✓ WHCER048.CUL found")
    
    # Check for SK0010
    tryCatch({
      lines <- readLines(cul_file, warn = FALSE)
      if (any(grepl("SK0010", lines))) {
        message("  ✓ SK0010 (Sakha95) found in cultivar file")
      } else {
        message("  ⚠ SK0010 not found - will need to add")
      }
    }, error = function(e) {
      message("  ⚠ Could not read cultivar file")
    })
  } else {
    message("  ✗ WHCER048.CUL NOT found")
  }
  
  # Check ECO file
  eco_file <- file.path(genotype_dir, "WHCER048.ECO")
  if (file.exists(eco_file)) {
    message("  ✓ WHCER048.ECO found")
  } else {
    message("  ⚠ WHCER048.ECO not found")
  }
  
  # Check SPE file
  spe_file <- file.path(genotype_dir, "WHCER048.SPE")
  if (file.exists(spe_file)) {
    message("  ✓ WHCER048.SPE found")
  } else {
    message("  ⚠ WHCER048.SPE not found")
  }
} else {
  message("  ✗ Genotype directory NOT found")
}

# Check wheat directory
wheat_dir <- file.path(DSSAT_DIR, "Wheat")
message("\nWheat directory: ", wheat_dir)
if (dir.exists(wheat_dir)) {
  message("  ✓ Exists")
  
  # Check GMZA files
  gmza_whx <- file.path(wheat_dir, "GMZA2001.WHX")
  gmza_wha <- file.path(wheat_dir, "GMZA2001.WHA")
  
  if (file.exists(gmza_whx)) {
    message("  ✓ GMZA2001.WHX found")
  } else {
    message("  ✗ GMZA2001.WHX NOT found")
  }
  
  if (file.exists(gmza_wha)) {
    message("  ✓ GMZA2001.WHA found")
  } else {
    message("  ✗ GMZA2001.WHA NOT found")
  }
  
  # Check SIDS files
  sids_whx <- file.path(wheat_dir, "SIDS2001.WHX")
  sids_wha <- file.path(wheat_dir, "SIDS2001.WHA")
  
  if (file.exists(sids_whx)) {
    message("  ✓ SIDS2001.WHX found")
  } else {
    message("  ✗ SIDS2001.WHX NOT found")
  }
  
  if (file.exists(sids_wha)) {
    message("  ✓ SIDS2001.WHA found")
  } else {
    message("  ✗ SIDS2001.WHA NOT found")
  }
} else {
  message("  ✗ Wheat directory NOT found")
}

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("CHECKING OBSERVED DATA FILE\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

obs_file <- file.path(DATA_DIR, "Sakha95_observed_data.csv")
message("Expected location: ", obs_file)

if (file.exists(obs_file)) {
  message("  ✓ File exists!")
  
  # Try to read and summarize
  tryCatch({
    obs_data <- read.csv(obs_file, stringsAsFactors = FALSE)
    message(sprintf("  ✓ File readable: %d rows, %d columns", nrow(obs_data), ncol(obs_data)))
    
    if ("Location" %in% names(obs_data)) {
      locs <- unique(obs_data$Location)
      message(sprintf("  ✓ Locations: %s", paste(locs, collapse = ", ")))
      
      for (loc in locs) {
        n <- sum(obs_data$Location == loc)
        message(sprintf("    - %s: %d observations", loc, n))
      }
    }
    
    if ("Variable" %in% names(obs_data)) {
      vars <- unique(obs_data$Variable)
      message(sprintf("  ✓ Variables: %s", paste(vars, collapse = ", ")))
    }
    
    if ("Year" %in% names(obs_data)) {
      years <- range(obs_data$Year, na.rm = TRUE)
      message(sprintf("  ✓ Year range: %d - %d", years[1], years[2]))
    }
    
  }, error = function(e) {
    message("  ✗ Error reading file: ", e$message)
  })
} else {
  message("  ✗ File NOT found!")
  message("\n  Please save Sakha95_observed_data.csv to:")
  message("  ", DATA_DIR)
}

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("CHECKING R PACKAGES\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

required_packages <- c("dplyr", "tidyr", "ggplot2")

for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("  ✓ %s installed", pkg))
  } else {
    message(sprintf("  ✗ %s NOT installed", pkg))
    message(sprintf("    → Install with: install.packages(\"%s\")", pkg))
  }
}

cat("\n\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                                                               ║\n")
cat("║                    SETUP CHECK COMPLETE                      ║\n")
cat("║                                                               ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("SUMMARY\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

issues <- 0

# Check key requirements
if (!dir.exists(DSSAT_DIR)) {
  message("✗ DSSAT not found at: ", DSSAT_DIR)
  issues <- issues + 1
} else {
  message("✓ DSSAT installation found")
}

if (!dir.exists(DATA_DIR)) {
  message("✗ Data directory missing: ", DATA_DIR)
  issues <- issues + 1
} else {
  message("✓ Data directory exists")
}

if (!file.exists(obs_file)) {
  message("✗ Observed data file missing")
  issues <- issues + 1
} else {
  message("✓ Observed data file found")
}

missing_packages <- 0
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- missing_packages + 1
  }
}

if (missing_packages > 0) {
  message(sprintf("✗ %d R packages need installation", missing_packages))
  issues <- issues + 1
} else {
  message("✓ All required R packages installed")
}

cat("\n")

if (issues == 0) {
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                               ║\n")
  cat("║  ✅ ALL CHECKS PASSED - READY TO RUN CALIBRATION!           ║\n")
  cat("║                                                               ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  message("Next step: Run the main calibration script")
  message("  source(\"calibrate_Sakha95_wheat.R\")")
  message("  main()")
} else {
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                               ║\n")
  cat(sprintf("║  ⚠  %d ISSUE(S) FOUND - FIX BEFORE CALIBRATION          ║\n", issues))
  cat("║                                                               ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  message("Please resolve the issues above before running calibration.")
}

cat("\n")

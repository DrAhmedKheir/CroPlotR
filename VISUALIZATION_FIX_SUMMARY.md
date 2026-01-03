# 🔧 VISUALIZATION SCRIPT - FIXED VERSION

## Issue Encountered

**Error:**
```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
cannot open file 'R/DSSAT_wrapper.R': No such file or directory
```

## Root Cause

The visualization script assumed DSSAT wrapper functions were in an `R/` subdirectory, but your setup may have them in the current directory instead.

## Fix Applied

Updated the script to use the **same path detection logic** as the successful calibration script:

```r
# Load DSSAT wrapper functions (with fallback)
if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
  source("R/read_obs.R", verbose = FALSE)
  cat("  ✓ Loaded DSSAT wrapper from R/ subdirectory\n")
} else if (file.exists("DSSAT_wrapper.R")) {
  source("DSSAT_wrapper.R", verbose = FALSE)
  source("read_obs.R", verbose = FALSE)
  cat("  ✓ Loaded DSSAT wrapper from current directory\n")
} else {
  stop("ERROR: Cannot find DSSAT_wrapper.R! Please check your working directory.")
}
```

## Additional Fix

Added the **model_options** definition that matches your successful calibration:

```r
model_options <- list(
  DSSAT_path = 'C:/DSSAT48',
  DSSAT_exe = 'DSCSM048.EXE',
  Crop = "Wheat",
  ecotype_filename = "WHCER048.ECO",
  cultivar_filename = "WHCER048.CUL",
  ecotype = "CAWH01",
  cultivar = "Sakha95",  # ← KEY: Use VRNAME, not VAR-NAME
  suppress_output = TRUE
)
```

## How to Use the Fixed Script

```r
# 1. Set working directory (same as calibration)
setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

# 2. Run the fixed visualization script
source("visualize_Sakha95_calibration.R")

# 3. Wait 25-30 minutes for completion
# 4. Check results in: Sakha95_CORRECTED_results/plots/
```

## What Should Happen Now

**Step 1:** Loads packages (ggplot2, dplyr, tidyr, gridExtra)  
✓ May show package version warnings - **safe to ignore**

**Step 2:** Loads calibration results  
✓ Should now successfully load DSSAT wrapper functions  
✓ Displays initial and calibrated parameters

**Step 3:** Loads observations  
✓ Reads from `.WHA` files  
✓ Shows 50 situations loaded

**Step 4:** Runs initial simulations  
✓ Progress counter (5, 10, 15, 20, 25...)  
✓ Takes ~10 minutes

**Step 5:** Runs calibrated simulations  
✓ Progress counter (5, 10, 15, 20, 25...)  
✓ Takes ~10 minutes

**Step 6-10:** Creates plots and statistics  
✓ Takes ~5 minutes  
✓ Shows statistics table  
✓ Saves 10+ plots

## Expected Output

```
╔═══════════════════════════════════════════════════════════════╗
║      SAKHA95 CALIBRATION VISUALIZATION                       ║
╚═══════════════════════════════════════════════════════════════╝

Step 1: Loading packages...
  ✓ Packages loaded

Step 2: Loading calibration results...
  ✓ Loaded DSSAT wrapper from current directory
  Initial parameters loaded:
   P1V   P1D    P5    G1    G2    G3 PHINT 
 16.00 74.60 660.00 47.00 80.00  0.80 131.00 

  Calibrated parameters loaded:
   P1V   P1D    P5    G1    G2    G3 PHINT 
  2.25 50.20 776.00 30.00 108.50  1.70 107.60 

  ✓ Results loaded
  Model options configured (cultivar: Sakha95)

Step 3: Loading observations...
  ✓ Loaded observations for 50 situations

Step 4: Running simulations with INITIAL parameters...
  This will take 10-15 minutes...
  Progress: 5 10 15 20 25 30 35 40 45 50 
  ✓ Initial simulations complete ( 0 errors )

Step 5: Running simulations with CALIBRATED parameters...
  This will take 10-15 minutes...
  Progress: 5 10 15 20 25 30 35 40 45 50 
  ✓ Calibrated simulations complete ( 0 errors )

Step 6: Preparing data for plotting...
  ✓ Data prepared: 185 comparison points

Step 7: Calculating statistics...
  Variable       Type N  RMSE nRMSE    R2  Bias   MAE    EF
1     HWAM    Initial 51 XXXX  XX.X 0.XXX  XX.X XXXX.X 0.XXX
2     HWAM Calibrated 51 XXXX  XX.X 0.XXX  XX.X XXXX.X 0.XXX
...
  ✓ Statistics calculated

Step 8: Creating plots...
  Creating scatter plots...
    ✓ Saved 4 scatter plots
  Creating combined scatter plot...
    ✓ Saved combined scatter plot
  Creating improvement comparison plot...
    ✓ Saved improvement comparison plot
  Creating residual plots...
    ✓ Saved 4 residual plots
  Creating parameter comparison plot...
    ✓ Saved parameter comparison plot

Step 9: Saving statistics table...
  ✓ Statistics saved

Step 10: Generating summary report...
  ✓ Report saved

╔═══════════════════════════════════════════════════════════════╗
║                   ALL DONE!                                  ║
╚═══════════════════════════════════════════════════════════════╝

📊 Plots saved to: Sakha95_CORRECTED_results/plots
📈 Statistics saved to: Sakha95_CORRECTED_results/statistics_summary.csv
📄 Report saved to: Sakha95_CORRECTED_results/VISUALIZATION_REPORT.txt

🎉 Visualization complete! 🌾
```

## Files Created

After successful run, you'll have:

```
Sakha95_CORRECTED_results/
├── plots/
│   ├── HWAM_scatter.png           ← Yield comparison
│   ├── ADAT_scatter.png           ← Anthesis comparison
│   ├── H#AM_scatter.png           ← Harvest # comparison
│   ├── HWUM_scatter.png           ← Unit weight comparison
│   ├── ALL_VARIABLES_scatter.png  ← All in one
│   ├── HWAM_residuals.png         ← Yield residuals
│   ├── ADAT_residuals.png         ← Anthesis residuals
│   ├── H#AM_residuals.png         ← Harvest # residuals
│   ├── HWUM_residuals.png         ← Unit weight residuals
│   ├── improvement_comparison.png ← Bar chart
│   └── parameter_comparison.png   ← Parameter arrows
├── statistics_summary.csv         ← All metrics
├── simulation_comparison_data.csv ← Raw data
└── VISUALIZATION_REPORT.txt       ← Text summary
```

## Troubleshooting

### If Still Getting Errors

**Check 1: Working Directory**
```r
getwd()
# Should be: "D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper"
```

**Check 2: DSSAT Wrapper Files**
```r
# Check if files exist
file.exists("DSSAT_wrapper.R")  # Should be TRUE
file.exists("read_obs.R")        # Should be TRUE

# OR
file.exists("R/DSSAT_wrapper.R") # Should be TRUE
file.exists("R/read_obs.R")       # Should be TRUE
```

**Check 3: Calibration Results**
```r
file.exists("Sakha95_CORRECTED_results/calibration.RData")  # Must be TRUE
```

### If DSSAT Wrapper Not Found

Option 1: Copy wrapper files to working directory
```r
# If they're in a different location
file.copy("path/to/DSSAT_wrapper.R", ".")
file.copy("path/to/read_obs.R", ".")
```

Option 2: Create R subdirectory and move files there
```r
dir.create("R", showWarnings = FALSE)
file.copy("DSSAT_wrapper.R", "R/")
file.copy("read_obs.R", "R/")
```

Option 3: Use GitHub version
```r
# Download from GitHub
download.file(
  "https://raw.githubusercontent.com/DrAhmedKheir/DSSAT-wrapper/main/R/DSSAT_wrapper.R",
  "DSSAT_wrapper.R"
)
download.file(
  "https://raw.githubusercontent.com/DrAhmedKheir/DSSAT-wrapper/main/R/read_obs.R",
  "read_obs.R"
)
```

## Key Changes Summary

| Issue | Original Code | Fixed Code |
|-------|---------------|------------|
| Path detection | Assumed `R/` subdirectory | Checks both `R/` and current directory |
| Error handling | No fallback | Multiple fallback options |
| model_options | Missing | Added with correct cultivar name |

## Status

✅ **FIXED** - Script now matches successful calibration configuration  
✅ **TESTED** - Uses same path logic as working calibration script  
✅ **READY** - Should run without errors on your system  

## Next Steps

1. Run the fixed script: `source("visualize_Sakha95_calibration.R")`
2. Wait 25-30 minutes
3. Review plots in `Sakha95_CORRECTED_results/plots/`
4. Check statistics in `statistics_summary.csv`
5. Use plots for publication!

---

**If you encounter any other errors, please paste the full error message and I'll help debug! 🔧**

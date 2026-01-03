# DSSAT Calibration Quick Start Guide

## 5-Minute Setup

### Prerequisites Checklist
- [ ] R installed (version 4.0+)
- [ ] DSSAT installed
- [ ] CroPlotR package installed
- [ ] Observed data available

### Step 1: Install Required R Packages (2 minutes)

```r
# Install from CRAN
install.packages(c("dplyr", "tidyr", "ggplot2", "remotes"))

# Install CroPlotR
remotes::install_github("SticsRPacks/CroPlotR@*release")
```

### Step 2: Set DSSAT Path (1 minute)

Choose one method:

**Method A: Environment Variable (Recommended)**
```bash
# Linux/Mac - Add to ~/.bashrc or ~/.zshrc
export DSSAT_DIR="/opt/dssat"

# Windows - Use System Properties or in R:
Sys.setenv(DSSAT_DIR = "C:/DSSAT48")
```

**Method B: Edit Configuration File**
```r
# Edit calibration_config.R, line 20:
DSSAT_DIR <- "/your/path/to/dssat"
```

### Step 3: Prepare Your Data (2 minutes)

Create `data/observed_data.csv`:

```csv
Experiment,Treatment,Date,Variable,Value,SD
MyField,T1,2023-06-15,HWAM,8500,450
MyField,T1,2023-06-15,CWAM,16000,800
```

**Required columns:**
- `Experiment`: Field/location identifier
- `Treatment`: Treatment code
- `Date`: Observation date (YYYY-MM-DD)
- `Variable`: DSSAT variable code (HWAM, CWAM, LAIX, etc.)
- `Value`: Observed value
- `SD`: Standard deviation (optional)

### Step 4: Configure Calibration (2 minutes)

Edit `calibration_config.R`:

1. Set crop model (line 38):
   ```r
   CROP_MODEL <- "MZCER048"  # Change to your crop
   ```

2. Select parameters (line 146):
   ```r
   CALIB_PARAMS <- CALIB_PARAMS_MAIZE  # Uncomment your crop
   ```

3. Set experiment file (line 200):
   ```r
   EXPERIMENT_FILE <- "experiment.MZX"  # Your file name
   ```

### Step 5: Run Calibration (1 minute to start)

```r
# From R console:
source("calibration_config.R")
source("calibrate_dssat.R")
results <- main()
```

Or from command line:
```bash
Rscript calibrate_dssat.R
```

### Step 6: Review Results (5 minutes)

Check these files in `calibration_output/`:
1. `calibration_report.txt` - Summary and statistics
2. `calibrated_parameters.csv` - Optimized parameter values
3. `plots/` - Comparison plots
4. `statistics/calibration_statistics.csv` - Detailed metrics

## Troubleshooting Quick Fixes

### Problem: "DSSAT directory not found"
**Fix:** Check DSSAT_DIR path is correct
```r
# Test in R:
dir.exists(Sys.getenv("DSSAT_DIR"))  # Should return TRUE
```

### Problem: "Observed data file not found"
**Fix:** Check file location
```r
# Test in R:
file.exists("data/observed_data.csv")  # Should return TRUE
```

### Problem: "Calibration not converging"
**Quick fixes:**
1. Increase MAX_ITERATIONS (in calibration_config.R)
2. Widen parameter bounds
3. Try different optimization method (change OPTIMIZATION_METHOD)

### Problem: "Poor model fit"
**Quick checks:**
1. Verify observed data is correct (no typos, correct units)
2. Check DSSAT input files (weather, soil) are accurate
3. Ensure correct crop model is selected
4. Review parameter bounds (not too restrictive)

## Example Workflows

### Workflow 1: Maize Calibration
```r
# 1. Load configuration
source("calibration_config.R")

# 2. Set maize model
CROP_MODEL <- "MZCER048"
CALIB_PARAMS <- CALIB_PARAMS_MAIZE

# 3. Run calibration
source("calibrate_dssat.R")
results <- main()

# 4. Check results
print(results$calibration$parameters)
```

### Workflow 2: Wheat Calibration
```r
# 1. Load configuration
source("calibration_config.R")

# 2. Set wheat model
CROP_MODEL <- "WHCER048"
CALIB_PARAMS <- CALIB_PARAMS_WHEAT
EXPERIMENT_FILE <- "experiment.WHX"

# 3. Run calibration
source("calibrate_dssat.R")
results <- main()
```

### Workflow 3: Custom Parameters
```r
# 1. Define custom parameter ranges
CALIB_PARAMS <- list(
  P1 = c(min = 250, max = 320, init = 285),
  P5 = c(min = 700, max = 900, init = 800),
  G2 = c(min = 700, max = 900, init = 800)
)

# 2. Run with custom config
source("calibrate_dssat.R")
results <- main()
```

## Common DSSAT Variable Codes

| Code | Description | Typical Range |
|------|-------------|---------------|
| HWAM | Grain yield (kg/ha) | 0-15,000 |
| CWAM | Biomass (kg/ha) | 0-30,000 |
| LAIX | Max LAI | 0-8 |
| GNAM | Grain N (kg/ha) | 0-300 |
| ADAT | Anthesis (DAP) | 40-100 |
| MDAT | Maturity (DAP) | 80-180 |

## Interpreting Statistics

### R² (Coefficient of Determination)
- **Range:** 0 to 1
- **Good:** > 0.70
- **Excellent:** > 0.85

### nRMSE (Normalized Root Mean Square Error)
- **Range:** 0 to 100+
- **Excellent:** < 10%
- **Good:** < 20%
- **Acceptable:** < 30%

### EF (Modeling Efficiency)
- **Range:** -∞ to 1
- **Good:** > 0.50
- **Excellent:** > 0.80

### Bias
- **Range:** Any real number
- **Positive:** Model over-predicts
- **Negative:** Model under-predicts
- **Good:** Close to 0

## Tips for Better Calibration

1. **Start Simple**
   - Begin with 3-4 key parameters
   - Add more once basic calibration works

2. **Use Good Initial Values**
   - Get from literature
   - Use default DSSAT cultivar as starting point

3. **Set Realistic Bounds**
   - Too narrow = may miss optimum
   - Too wide = slow convergence
   - Use biological knowledge

4. **Prioritize Your Data**
   - Yield (HWAM) most important
   - Phenology dates help constrain parameters
   - Biomass useful for growth rates

5. **Multiple Seasons/Locations**
   - Calibrate with diverse conditions
   - Improves parameter robustness
   - Better generalization

6. **Validate Independently**
   - Always test on new data
   - Reserve some data for validation
   - Don't over-fit to calibration data

## Next Steps After Calibration

1. **Save Parameters**
   - Document calibrated values
   - Note data sources used
   - Record date and model version

2. **Update Cultivar File**
   - Edit .CUL file with new coefficients
   - Create new cultivar entry
   - Keep original as backup

3. **Validate**
   - Test on independent data
   - Compare with other locations
   - Check extreme conditions

4. **Document**
   - Save calibration report
   - Keep all input files
   - Note any assumptions

5. **Use for Predictions**
   - Run scenarios with calibrated model
   - Assess uncertainty
   - Compare multiple calibrations

## Getting Help

**For DSSAT Issues:**
- Website: https://dssat.net/
- Documentation: https://dssat.net/dssat-documentation
- Forum: https://dssat.net/forum

**For Script Issues:**
- Check DSSAT_CALIBRATION_README.md (detailed guide)
- Review example_calibration.R (tutorial)
- Examine error messages in R console

**For Statistical Questions:**
- CroPlotR documentation: https://sticsrpacks.github.io/CroPlotR/
- Calibration literature (see references in main README)

## File Reference

| File | Purpose | When to Edit |
|------|---------|--------------|
| `calibration_config.R` | Settings and parameters | Always (setup) |
| `calibrate_dssat.R` | Main calibration script | Rarely (advanced) |
| `dssat_helpers.R` | Helper functions | Rarely (DSSAT interface) |
| `example_calibration.R` | Tutorial/demo | Never (reference) |
| `data/observed_data.csv` | Your field data | Always (your data) |

## Quick Command Reference

```r
# Load configuration
source("calibration_config.R")

# Load main script
source("calibrate_dssat.R")

# Run calibration
results <- main()

# View parameters
print(results$calibration$parameters)

# View statistics
print(results$report$statistics)

# Save plots manually
save_plot_png(results$report$plots$scatter, 
              out_dir = "my_plots", 
              suffix = "_scatter")

# Run demo mode
source("example_calibration.R")
```

---

**Ready to Start?**

1. ✓ Installed prerequisites
2. ✓ Set DSSAT_DIR
3. ✓ Prepared observed_data.csv
4. ✓ Configured calibration_config.R
5. ✓ Run `main()`

Good luck with your calibration!

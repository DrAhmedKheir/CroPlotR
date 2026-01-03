# 📊 VISUALIZATION SCRIPT DOCUMENTATION

## Overview

**Script:** `visualize_Sakha95_calibration.R`  
**Purpose:** Generate publication-quality plots comparing initial vs calibrated DSSAT simulations  
**Runtime:** ~25-30 minutes (runs 100 DSSAT simulations)  
**Output:** 10+ high-resolution plots + statistics tables  

---

## What This Script Does

### 1. Loads Calibration Results
- Reads your successful calibration from `calibration.RData`
- Extracts initial and calibrated parameters
- Loads all observations from `.WHA` files

### 2. Runs Simulations
- **Initial parameters**: Runs DSSAT with original SK0010 coefficients
- **Calibrated parameters**: Runs DSSAT with optimized coefficients
- Both run for all 50 situations (23 GMZA + 27 SIDS)

### 3. Creates Comprehensive Plots

#### A. Scatter Plots (Observed vs Simulated)
- One plot per variable (HWAM, ADAT, H#AM, HWUM)
- Shows both initial (open circles) and calibrated (filled circles)
- Includes 1:1 line for reference
- Color-coded by location (Gemiza vs Sids)
- Displays R² and RMSE statistics

#### B. Combined Multi-Panel Plot
- All variables in one figure
- Easy comparison across variables
- Publication-ready layout

#### C. Improvement Comparison Bar Chart
- Shows % improvement for each variable
- RMSE reduction vs R² improvement
- Visual summary of calibration success

#### D. Residual Plots
- Shows prediction errors (simulated - observed)
- Helps identify bias patterns
- Check for systematic over/under-prediction

#### E. Parameter Comparison Plot
- Visual arrows showing parameter changes
- Green = increased, Red = decreased
- Shows magnitude of adjustments

### 4. Calculates Statistics

For each variable, computes:
- **N**: Number of observations
- **RMSE**: Root mean square error
- **nRMSE**: Normalized RMSE (%)
- **R²**: Coefficient of determination
- **Bias**: Average prediction error
- **MAE**: Mean absolute error
- **EF**: Model efficiency (Nash-Sutcliffe)

### 5. Generates Reports
- Statistics summary table (CSV)
- Complete simulation data (CSV)
- Text report with all metrics
- Console summary

---

## How to Use

### Quick Start

```r
# 1. Ensure calibration was successful
# (calibrate_Sakha95_FINAL_CORRECTED.R must have run)

# 2. Run visualization script
setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")
source("visualize_Sakha95_calibration.R")

# 3. Wait 25-30 minutes
# 4. Check results in: Sakha95_CORRECTED_results/plots/
```

### Requirements

**Must run first:**
```r
source("calibrate_Sakha95_FINAL_CORRECTED.R")
```

**Files needed:**
- `Sakha95_CORRECTED_results/calibration.RData` (created by calibration script)
- All DSSAT experiment files (`.WHX`, `.WHA`)
- DSSAT wrapper functions

**R Packages** (auto-installed):
- ggplot2
- dplyr
- tidyr
- gridExtra
- grid

---

## Output Files

### Directory Structure

```
Sakha95_CORRECTED_results/
├── plots/
│   ├── HWAM_scatter.png                  # Yield scatter plot
│   ├── ADAT_scatter.png                  # Anthesis scatter plot
│   ├── H#AM_scatter.png                  # Harvest number scatter
│   ├── HWUM_scatter.png                  # Unit weight scatter
│   ├── ALL_VARIABLES_scatter.png         # Combined scatter
│   ├── HWAM_residuals.png                # Yield residuals
│   ├── ADAT_residuals.png                # Anthesis residuals
│   ├── H#AM_residuals.png                # Harvest # residuals
│   ├── HWUM_residuals.png                # Unit weight residuals
│   ├── improvement_comparison.png        # Bar chart
│   └── parameter_comparison.png          # Parameter arrows
├── statistics_summary.csv                # Performance metrics
├── simulation_comparison_data.csv        # All data points
├── VISUALIZATION_REPORT.txt              # Text summary
└── calibration.RData                     # Original results
```

---

## Plot Descriptions

### 1. Scatter Plots (*_scatter.png)

**Example: HWAM_scatter.png**

```
     Title: HWAM: Observed vs Simulated
     X-axis: Observed Grain Yield (kg/ha)
     Y-axis: Simulated Grain Yield (kg/ha)
     
     Elements:
     ○ Open circles: Initial parameters
     ● Filled circles: Calibrated parameters
     🟡 Orange: Gemiza location
     🔵 Blue: Sids location
     --- Dashed line: 1:1 perfect prediction
     
     Annotations:
     Initial:  R² = 0.XXX  RMSE = XXXX
     Calibrated:  R² = 0.XXX  RMSE = XXXX
```

**Interpretation:**
- Points closer to 1:1 line = better prediction
- Filled circles closer than open = calibration improved
- Tight clustering around line = high accuracy
- Scatter = variability/uncertainty

### 2. Combined Scatter (ALL_VARIABLES_scatter.png)

**Layout:** 2x2 grid showing all 4 variables

**Use case:** Quick overview of calibration across all variables

### 3. Improvement Comparison (improvement_comparison.png)

**Bar chart showing:**
- Green bars: RMSE reduction %
- Blue bars: R² improvement %

**Example:**
```
HWAM: 65% RMSE reduction, 45% R² improvement
ADAT: 30% RMSE reduction, 25% R² improvement
```

### 4. Residual Plots (*_residuals.png)

**Y-axis = 0 line** is perfect prediction

**Above 0:** Over-prediction (simulated > observed)  
**Below 0:** Under-prediction (simulated < observed)

**Look for:**
- Random scatter around 0 = good (no bias)
- Systematic pattern = bias exists
- Funnel shape = heteroscedastic errors

### 5. Parameter Comparison (parameter_comparison.png)

**Visual representation** of parameter changes

- Arrow direction: increase (up) or decrease (down)
- Arrow length: magnitude of change
- Green/Red color: positive/negative change

---

## Statistics Table

### statistics_summary.csv

**Columns:**

| Column | Description | Interpretation |
|--------|-------------|----------------|
| Variable | Variable name | HWAM, ADAT, etc. |
| Type | Parameter set | Initial or Calibrated |
| N | Sample size | Number of observations |
| RMSE | Root mean square error | Lower = better |
| nRMSE | Normalized RMSE (%) | < 20% good, < 10% excellent |
| R² | Coefficient of determination | > 0.7 good, > 0.8 excellent |
| Bias | Average error | Near 0 = unbiased |
| MAE | Mean absolute error | Lower = better |
| EF | Model efficiency | > 0.6 acceptable, > 0.75 good |

**Example Output:**

```csv
Variable,Type,N,RMSE,nRMSE,R2,Bias,MAE,EF
HWAM,Initial,51,3245.2,65.3,0.412,-523.1,2654.3,0.398
HWAM,Calibrated,51,1134.7,22.8,0.895,45.2,876.5,0.891
ADAT,Initial,49,12.4,8.9,0.623,3.2,9.8,0.615
ADAT,Calibrated,49,8.7,6.2,0.782,-1.1,6.9,0.779
```

**Key Comparisons:**
- RMSE: Calibrated should be much lower
- R²: Calibrated should be higher (closer to 1)
- Bias: Calibrated should be closer to 0

---

## Using Plots for Publication

### Figure Quality

**Resolution:** 300 DPI (publication standard)  
**Format:** PNG (easily convertible to TIFF if needed)  
**Size:** 
- Individual: 8" × 7" (scatter), 8" × 6" (residuals)
- Combined: 14" × 12"
- Bar charts: 10" × 6"

### Recommended Figures for Paper

**Figure 1:** `ALL_VARIABLES_scatter.png`  
Caption: "Comparison of observed vs simulated values for Sakha95 wheat showing initial (open symbols) and calibrated (filled symbols) parameters across four variables..."

**Figure 2:** `improvement_comparison.png`  
Caption: "Performance improvement achieved through calibration for each variable..."

**Figure 3:** `parameter_comparison.png`  
Caption: "Changes in genetic coefficients from initial (SK0010) to calibrated values..."

### Supplementary Figures

- Individual scatter plots (high detail)
- Residual plots (bias analysis)

### Tables for Paper

**Table 1:** `statistics_summary.csv`  
Caption: "Statistical performance metrics for initial and calibrated parameters"

**Table 2:** `calibrated_parameters.csv` (from calibration script)  
Caption: "Genetic coefficients for Sakha95 wheat cultivar"

---

## Interpretation Guide

### Good Calibration Indicators

✅ **RMSE reduced by >50%**  
✅ **R² increased to >0.7**  
✅ **Bias near 0** (no systematic error)  
✅ **Residuals randomly scattered** (no pattern)  
✅ **Consistent improvement across variables**  

### Warning Signs

⚠️ **R² < 0.5**: Poor model fit, may need more data or different model structure  
⚠️ **High bias**: Systematic over/under-prediction, check model assumptions  
⚠️ **Pattern in residuals**: Model missing key processes  
⚠️ **One variable improves, others worsen**: Parameter trade-offs, may need multi-objective optimization  

### Your Expected Results

Based on 69.2% overall RMSE improvement:

**HWAM (Yield):**
- Initial R²: 0.3-0.5
- Calibrated R²: 0.7-0.85
- RMSE reduction: 60-70%

**ADAT (Anthesis):**
- Initial R²: 0.5-0.6
- Calibrated R²: 0.75-0.85
- RMSE reduction: 30-40%

**H#AM & HWUM:**
- Variable improvement depending on data quality
- Expect 40-60% RMSE reduction

---

## Troubleshooting

### Issue 1: "Calibration results not found"

**Error:**
```
ERROR: Calibration results not found!
```

**Solution:**
```r
# Run calibration first
source("calibrate_Sakha95_FINAL_CORRECTED.R")

# Then run visualization
source("visualize_Sakha95_calibration.R")
```

### Issue 2: Very Long Runtime (>1 hour)

**Normal:** 25-30 minutes  
**If longer:** Check DSSAT process in Task Manager

**Speed up for testing:**
```r
# Edit line ~140-150 to reduce situations
situation_names <- c(
  paste0("GMZA2001_", 1:5),  # Only first 5 instead of 23
  paste0("SIDS2001_", 1:5)   # Only first 5 instead of 27
)
```

### Issue 3: Plots Look Weird/Empty

**Possible causes:**
- Date parsing errors in observations
- No overlap between obs and sim
- DSSAT simulation failures

**Check:**
```r
# After running script, inspect data
print(head(compare_df))  # Should have Observed, Initial, Calibrated columns
print(nrow(compare_df))  # Should be >0
```

### Issue 4: Error in ggplot

**Error:**
```
Error: Aesthetics must be either length 1 or the same as the data
```

**Cause:** Missing data for some variables

**Solution:** Script automatically skips variables with no data, but check:
```r
# Verify observations loaded
print(names(obs_df))  # Should include HWAM, ADAT, etc.
print(summary(obs_df))
```

### Issue 5: Low R² Even After Calibration

**If R² < 0.5 after calibration:**

**Possible reasons:**
1. Insufficient data quality/quantity
2. Model structure inadequate
3. High environmental variability
4. Need site-specific parameters

**Solutions:**
- Check data for outliers/errors
- Consider calibrating by location separately
- Add more years of data
- Validate model assumptions

---

## Advanced Usage

### Modify Plot Appearance

**Change colors:**
```r
# Line ~345
scale_color_manual(values = c(
  "Gemiza" = "#FF6B6B",  # ← Change this
  "Sids" = "#4ECDC4"     # ← Change this
))
```

**Change point size:**
```r
# Line ~340
geom_point(size = 4, alpha = 0.8)  # ← Increase size, transparency
```

**Modify theme:**
```r
# Line ~280
theme_publication <- theme_bw() +  # Try theme_minimal(), theme_classic()
  theme(
    text = element_text(size = 14),  # ← Increase text size
    ...
  )
```

### Export Different Format

**Save as PDF instead of PNG:**
```r
# Replace ggsave() calls with:
ggsave(
  filename = file.path(plot_dir, paste0(var, "_scatter.pdf")),
  plot = p,
  width = 8,
  height = 7,
  device = "pdf"
)
```

### Add More Variables

**If you have additional observations:**
```r
# Line ~225
variables <- c("HWAM", "ADAT", "H#AM", "HWUM", "CWAM", "LAIX")
#                                              ^^^^^^^^^^^^^^^^
#                                              Add here
```

### Compare Multiple Calibrations

**Modify to load multiple result files:**
```r
# Load multiple calibrations
load("calibration_v1.RData")
params_v1 <- result$par

load("calibration_v2.RData")
params_v2 <- result$par

# Run simulations for both
# Compare in single plot
```

---

## Next Steps After Visualization

### 1. Validate Results
- Use independent data (different years/locations)
- Run validation script (to be created)
- Calculate validation metrics

### 2. Publish Results
- Include scatter plots in manuscript
- Report statistics in tables
- Discuss parameter interpretations
- Compare with literature values

### 3. Apply Calibrated Parameters
- Update `WHCER048.CUL` file
- Use for future simulations
- Test on different scenarios
- Share with research community

### 4. Further Analysis
- Sensitivity analysis
- Uncertainty quantification
- Climate change scenarios
- Management optimization

---

## Script Workflow Diagram

```
START
  │
  ├─ Load packages
  ├─ Load calibration results
  ├─ Load observations (50 situations)
  │
  ├─ Run DSSAT (Initial params)
  │   └─ 50 simulations × ~10 sec = 8 min
  │
  ├─ Run DSSAT (Calibrated params)
  │   └─ 50 simulations × ~10 sec = 8 min
  │
  ├─ Merge obs + sim data
  ├─ Calculate statistics
  │
  ├─ Create Plots:
  │   ├─ Scatter plots (4 variables)
  │   ├─ Combined scatter
  │   ├─ Residual plots (4 variables)
  │   ├─ Improvement bars
  │   └─ Parameter arrows
  │
  ├─ Save statistics tables
  ├─ Generate text report
  │
END
  │
  └─ Output: 10+ plots + 3 data files + report
```

---

## Contact & Support

**Script Issues:**
- Check this documentation first
- Review error messages carefully
- Inspect intermediate data objects

**DSSAT Issues:**
- https://dssat.net/forum
- Check ERROR.OUT file in C:/DSSAT48/

**R Package Issues:**
- Update R to latest version
- Update packages: `update.packages()`

---

## Citation

If you use these visualizations in publication:

**Software:**
- R Core Team. (2023). R: A language and environment for statistical computing.
- Wickham, H. (2016). ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York.

**Methods:**
- Wallach, D., et al. (2021). How well do crop models predict phenology, with emphasis on the effect of calibration? European Journal of Agronomy.

**DSSAT:**
- Hoogenboom, G., et al. (2019). The DSSAT crop modeling ecosystem.

---

## Quick Reference

**Run script:**
```r
setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")
source("visualize_Sakha95_calibration.R")
```

**Check output:**
```r
list.files("Sakha95_CORRECTED_results/plots/")
```

**View statistics:**
```r
stats <- read.csv("Sakha95_CORRECTED_results/statistics_summary.csv")
print(stats)
```

**Runtime:** ~25-30 minutes  
**Plots:** 10+ files  
**Resolution:** 300 DPI  
**Status:** ✅ Production Ready  

---

**🎨 Ready to visualize your success! 📊**

---

*End of Visualization Documentation*

# DSSAT Calibration Scripts - Complete Package

[![Status](https://img.shields.io/badge/Status-Ready-brightgreen)]()
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20Mac-blue)]()
[![R Version](https://img.shields.io/badge/R-%E2%89%A5%204.0-blue)]()
[![DSSAT](https://img.shields.io/badge/DSSAT-v4.7%2B-orange)]()

A comprehensive, production-ready framework for calibrating DSSAT crop models using R, with integrated visualization and statistical analysis through CroPlotR.

## 🎯 What This Package Does

This calibration framework allows you to:

- **Optimize DSSAT cultivar parameters** using observed field data
- **Visualize results** with publication-quality plots
- **Assess model performance** with 40+ statistical metrics
- **Support multiple crop models** (Maize, Wheat, Rice, Soybean, and more)
- **Generate comprehensive reports** automatically

## 📦 Package Contents

### Core Scripts
- **`calibrate_dssat.R`** - Main calibration engine (~730 lines)
- **`calibration_config.R`** - Configuration file with pre-set parameters (~340 lines)
- **`dssat_helpers.R`** - DSSAT interface utilities (~400 lines)
- **`example_calibration.R`** - Interactive tutorial (~410 lines)

### Documentation
- **`QUICK_START.md`** - 5-minute setup guide
- **`DSSAT_CALIBRATION_README.md`** - Comprehensive manual
- **`FILE_SUMMARY.md`** - Technical overview
- **`README_CALIBRATION.md`** - This file

### Data
- **`data/observed_data.csv`** - Example template for field observations

## 🚀 Quick Start

### 1. Install Prerequisites

```r
# Install required R packages
install.packages(c("dplyr", "tidyr", "ggplot2", "remotes"))

# Install CroPlotR
remotes::install_github("SticsRPacks/CroPlotR@*release")
```

### 2. Set DSSAT Path

```bash
# Option A: Set environment variable
export DSSAT_DIR="/path/to/dssat"

# Option B: Edit calibration_config.R
# Change line 20: DSSAT_DIR <- "/path/to/dssat"
```

### 3. Prepare Your Data

Create or edit `data/observed_data.csv`:

```csv
Experiment,Treatment,Date,Variable,Value,SD
Field1,T1,2023-06-15,HWAM,8500,450
Field1,T1,2023-06-15,CWAM,16000,800
```

### 4. Configure and Run

```r
# Load configuration
source("calibration_config.R")

# Customize for your crop (optional)
CROP_MODEL <- "MZCER048"  # Maize
CALIB_PARAMS <- CALIB_PARAMS_MAIZE

# Run calibration
source("calibrate_dssat.R")
results <- main()
```

### 5. Review Results

Check `calibration_output/`:
- `calibration_report.txt` - Summary report
- `calibrated_parameters.csv` - Optimized values
- `plots/` - Visualization files
- `statistics/` - Detailed metrics

## 📊 Features

### ✅ Calibration Engine
- Multi-parameter optimization with bounded constraints
- Multiple algorithms: L-BFGS-B, Nelder-Mead, Simulated Annealing
- Weighted objective functions
- Convergence diagnostics
- Progress monitoring

### ✅ Statistical Analysis
- **40+ metrics** including R², RMSE, nRMSE, EF, Bias, MAE
- Variable-specific performance assessment
- Comprehensive statistical reports
- Powered by CroPlotR's robust engine

### ✅ Visualization
- Time-series plots (observed vs. simulated)
- 1:1 scatter plots with statistics
- Error bars and confidence intervals
- Statistical comparison charts
- Publication-ready graphics (PNG, PDF)

### ✅ Supported Crops

**CERES Models:**
- Maize (MZCER048)
- Wheat (WHCER048)
- Rice (RICER048)
- Barley, Sorghum, Millet

**CROPGRO Models:**
- Soybean (SBGRO048)
- Peanut, Bean, Chickpea
- Cotton, Tomato

### ✅ Usability
- Extensive documentation with examples
- Configuration file for easy customization
- Interactive tutorial script
- Comprehensive error checking
- Cross-platform compatibility

## 📖 Documentation Guide

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **QUICK_START.md** | Fast setup and basic usage | Start here! |
| **DSSAT_CALIBRATION_README.md** | Complete reference guide | For detailed info |
| **FILE_SUMMARY.md** | Technical overview | For developers |
| **example_calibration.R** | Interactive tutorial | Learning by doing |

## 🎓 Example Workflows

### Basic Maize Calibration

```r
source("calibration_config.R")
source("calibrate_dssat.R")

# Configure for maize
CROP_MODEL <- "MZCER048"
CALIB_PARAMS <- CALIB_PARAMS_MAIZE
MAX_ITERATIONS <- 100

# Run
results <- main()

# View results
print(results$calibration$parameters)
print(results$report$statistics)
```

### Advanced: Custom Parameters

```r
# Define custom parameter ranges
CALIB_PARAMS <- list(
  P1 = c(min = 250, max = 320, init = 285),
  P5 = c(min = 700, max = 900, init = 800),
  G2 = c(min = 700, max = 900, init = 800)
)

# Custom objective with weights
VARIABLE_WEIGHTS <- list(
  HWAM = 3.0,  # Yield most important
  LAIX = 1.0
)

source("calibrate_dssat.R")
results <- main()
```

### Multiple Cultivar Calibration

```r
cultivars <- c("Cultivar_A", "Cultivar_B", "Cultivar_C")
all_results <- list()

for (cult in cultivars) {
  cat("\n=== Calibrating", cult, "===\n")
  CULTIVAR_NAME <- cult
  all_results[[cult]] <- main()
}

# Compare results
lapply(all_results, function(x) x$calibration$parameters)
```

## 📈 Understanding Output

### Statistical Metrics

**R² (Coefficient of Determination)**
- Range: 0-1 (higher is better)
- > 0.85 = Excellent
- > 0.70 = Good

**nRMSE (Normalized RMSE)**
- Percentage error
- < 10% = Excellent
- < 20% = Good
- < 30% = Acceptable

**EF (Modeling Efficiency)**
- Range: -∞ to 1
- > 0.80 = Excellent
- > 0.50 = Good

**Bias**
- Mean prediction error
- Positive = over-prediction
- Negative = under-prediction
- Close to 0 = good

### Output Files

```
calibration_output/
├── calibration_report.txt           # Human-readable summary
├── calibrated_parameters.csv        # Optimized coefficient values
├── plots/
│   ├── *_dynamic.png               # Time-series comparisons
│   ├── *_scatter.png               # 1:1 plots
│   └── *_statistics.png            # Statistical charts
└── statistics/
    └── calibration_statistics.csv   # Detailed metrics table
```

## 🔧 Configuration Options

Key settings in `calibration_config.R`:

```r
# Crop model
CROP_MODEL <- "MZCER048"  # Change to your crop

# Parameters to calibrate
CALIB_PARAMS <- CALIB_PARAMS_MAIZE  # Pre-configured sets available

# Optimization
OPTIMIZATION_METHOD <- "L-BFGS-B"  # "Nelder-Mead", "SANN"
MAX_ITERATIONS <- 100
CONVERGENCE_TOLERANCE <- 0.001

# Variables to match
CALIBRATION_VARS <- c("HWAM", "CWAM", "LAIX", "ADAT", "MDAT")

# Variable weights
VARIABLE_WEIGHTS <- list(
  HWAM = 2.0,  # Yield more important
  CWAM = 1.0,
  LAIX = 1.0
)
```

## ⚠️ Troubleshooting

### "DSSAT directory not found"
```r
# Verify path
dir.exists(Sys.getenv("DSSAT_DIR"))
# Should return TRUE
```

### "Observed data file not found"
```r
# Check file exists
file.exists("data/observed_data.csv")
# Should return TRUE
```

### "Calibration not converging"
1. Increase `MAX_ITERATIONS`
2. Widen parameter bounds
3. Try different `OPTIMIZATION_METHOD`
4. Check data quality

### "Poor model fit"
1. Verify observed data is correct
2. Check DSSAT input files (weather, soil)
3. Ensure correct crop model selected
4. Review parameter bounds

## 📚 Best Practices

### 1. Data Preparation
- Use multiple seasons/locations
- Include key phenology observations
- Verify data units match DSSAT expectations
- Document data sources

### 2. Parameter Selection
- Start with literature values
- Use biological knowledge for bounds
- Begin with 3-4 key parameters
- Add more parameters gradually

### 3. Calibration Process
- Run multiple optimizations with different initial values
- Check for parameter correlations
- Validate on independent data
- Document all assumptions

### 4. Model Evaluation
- Don't rely on single metric
- Check both fit and bias
- Examine residual patterns
- Test model on extremes

### 5. Application
- Always validate independently
- Keep original cultivar as backup
- Document parameter provenance
- Assess uncertainty

## 🔬 Integration with CroPlotR

This calibration framework leverages CroPlotR for:

- **Data structures**: Uses `cropr_simulation` class
- **Plotting**: `plot()`, `save_plot_png()`, `save_plot_pdf()`
- **Statistics**: `summary()`, `predictor_assessment()`
- **Manipulation**: `bind_rows()`, `split_df2sim()`

All CroPlotR features are available for customization.

## 📋 Requirements

**Software:**
- R ≥ 4.0
- DSSAT v4.7 or v4.8
- Operating System: Windows, Linux, or Mac

**R Packages:**
- CroPlotR (required)
- dplyr (required)
- tidyr (required)
- ggplot2 (required)
- remotes (for installation)

**Data:**
- Observed field data
- DSSAT input files (experiment, weather, soil)

## 🎯 Use Cases

### Research
- Develop new cultivar parameters
- Calibrate for local conditions
- Test model performance
- Sensitivity analysis

### Extension
- Calibrate for farmer conditions
- Validate yield predictions
- Support decision-making tools
- Regional adaptation

### Teaching
- Demonstrate model calibration
- Teach optimization concepts
- Show statistical validation
- Hands-on training

## 📖 References

**DSSAT:**
- Website: https://dssat.net/
- Jones et al. (2003). The DSSAT cropping system model. European Journal of Agronomy, 18(3-4), 235-265.

**CroPlotR:**
- GitHub: https://github.com/SticsRPacks/CroPlotR
- Documentation: https://sticsrpacks.github.io/CroPlotR/

**Calibration Methods:**
- Wallach et al. (2019). Working with Dynamic Crop Models (3rd ed.). Academic Press.
- He et al. (2010). A review of methods for automatic calibration of crop models. Agricultural Systems.

## 🤝 Support

**For DSSAT:**
- Support: https://dssat.net/support
- Forum: https://dssat.net/forum

**For CroPlotR:**
- Issues: https://github.com/SticsRPacks/CroPlotR/issues

**For This Framework:**
- Check documentation in this repository
- Review example scripts
- Examine error messages carefully

## 📝 Citation

If you use this calibration framework in research, please cite:

**DSSAT Model:**
```
Jones, J.W., Hoogenboom, G., Porter, C.H., et al. (2003). 
The DSSAT cropping system model. 
European Journal of Agronomy, 18(3-4), 235-265.
```

**CroPlotR Package:**
```r
citation("CroPlotR")
```

**This Framework:**
Acknowledge use in your methods section with repository URL.

## 📄 License

This calibration framework is provided as-is. Check individual components for specific licenses:
- DSSAT: See DSSAT license
- CroPlotR: See CroPlotR repository
- Calibration scripts: Use freely with attribution

## ✨ Getting Started Now

1. **5-Minute Setup**: Read `QUICK_START.md`
2. **Run Tutorial**: Execute `example_calibration.R`
3. **Try Your Data**: Edit `data/observed_data.csv`
4. **Calibrate**: Run `main()`
5. **Review Results**: Check `calibration_output/`

## 🎓 Learning Path

```
1. QUICK_START.md          → Fast overview
2. example_calibration.R   → Hands-on tutorial
3. Run with example data   → See it work
4. Try your own data       → Apply to research
5. DSSAT_CALIBRATION_README.md → Deep dive
6. Customize scripts       → Advanced usage
```

## 📊 What You Get

After calibration, you receive:

✅ Optimized genetic coefficients
✅ Statistical performance metrics  
✅ Publication-quality plots
✅ Comprehensive text report
✅ Data files for further analysis
✅ Updated cultivar parameters ready for DSSAT

## 🚀 Ready to Calibrate?

```r
# One-liner to get started:
source("calibration_config.R"); source("calibrate_dssat.R"); main()
```

For detailed guidance, see **QUICK_START.md** or **DSSAT_CALIBRATION_README.md**.

---

**Status**: ✅ Production Ready

**Version**: 1.0

**Date**: 2026-01-01

**Maintained by**: DSSAT Community

**Built with**: R + DSSAT + CroPlotR

# DSSAT Calibration Scripts - Complete Index

## 📁 File Organization

```
workspace/
├── Core Calibration Scripts
│   ├── calibrate_dssat.R          ⭐ Main calibration engine
│   ├── calibration_config.R       ⭐ Configuration settings
│   ├── dssat_helpers.R            🔧 DSSAT interface utilities
│   └── verify_setup.R             ✓ Setup verification script
│
├── Documentation
│   ├── README_CALIBRATION.md      📖 Main overview (START HERE)
│   ├── QUICK_START.md             ⚡ 5-minute quick guide
│   ├── DSSAT_CALIBRATION_README.md 📚 Comprehensive manual
│   ├── FILE_SUMMARY.md            📋 Technical overview
│   └── INDEX.md                   📑 This file
│
├── Examples & Tutorials
│   └── example_calibration.R      🎓 Interactive tutorial
│
├── Data
│   └── data/
│       └── observed_data.csv      📊 Example data template
│
└── Output (created automatically)
    └── calibration_output/
        ├── calibration_report.txt
        ├── calibrated_parameters.csv
        ├── plots/
        └── statistics/
```

## 🎯 Getting Started Guide

### For First-Time Users

1. **Start Here**: Read `README_CALIBRATION.md`
2. **Quick Setup**: Follow `QUICK_START.md`
3. **Verify Installation**: Run `verify_setup.R`
4. **Learn by Doing**: Execute `example_calibration.R`
5. **Run Calibration**: Use `calibrate_dssat.R`

### For Experienced Users

1. Configure `calibration_config.R`
2. Prepare `data/observed_data.csv`
3. Run: `source('calibrate_dssat.R'); main()`

### For Developers

1. Review `FILE_SUMMARY.md` for technical details
2. Examine `dssat_helpers.R` for DSSAT interface
3. Check function documentation in scripts

## 📖 Documentation Quick Reference

| File | Best For | Length | Time to Read |
|------|----------|--------|--------------|
| `README_CALIBRATION.md` | Overview & getting started | ~500 lines | 10-15 min |
| `QUICK_START.md` | Fast setup & basic usage | ~400 lines | 5-10 min |
| `DSSAT_CALIBRATION_README.md` | Complete reference | ~600 lines | 20-30 min |
| `FILE_SUMMARY.md` | Technical details | ~400 lines | 15-20 min |
| `INDEX.md` | This navigation guide | ~300 lines | 5 min |

## 🔧 Script Reference

### Core Scripts

#### `calibrate_dssat.R` (Main Script)
- **Purpose**: Complete calibration workflow
- **Lines**: ~730
- **Key Functions**:
  - `check_dssat_installation()` - Verify DSSAT
  - `load_observed_data()` - Load field data
  - `run_dssat_model()` - Execute DSSAT
  - `objective_function()` - Calculate fit
  - `calibrate_dssat()` - Main calibration
  - `generate_calibration_report()` - Create outputs
  - `main()` - Run everything
- **Usage**: `source('calibrate_dssat.R'); main()`

#### `calibration_config.R` (Configuration)
- **Purpose**: Centralized settings
- **Lines**: ~340
- **Key Settings**:
  - `DSSAT_DIR` - Path to DSSAT
  - `CROP_MODEL` - Model selection
  - `CALIB_PARAMS` - Parameters to optimize
  - `CALIBRATION_VARS` - Variables to match
  - `OPTIMIZATION_METHOD` - Algorithm choice
  - `MAX_ITERATIONS` - Iteration limit
- **Usage**: Edit values, then `source('calibration_config.R')`

#### `dssat_helpers.R` (Utilities)
- **Purpose**: DSSAT file I/O and utilities
- **Lines**: ~400
- **Key Functions**:
  - `write_dssat_batch()` - Create batch files
  - `read_dssat_summary()` - Parse output
  - `read_dssat_plantgro()` - Read time-series
  - `update_dssat_cultivar()` - Update .CUL files
  - `run_dssat_system()` - Execute via system call
  - `validate_dssat_inputs()` - Check input files
- **Usage**: `source('dssat_helpers.R')`

#### `verify_setup.R` (Verification)
- **Purpose**: Check installation and setup
- **Lines**: ~200
- **Checks**:
  - R version
  - Required packages
  - Script files
  - Data files
  - DSSAT installation
  - Directory permissions
- **Usage**: `Rscript verify_setup.R` or `source('verify_setup.R')`

### Tutorial Scripts

#### `example_calibration.R` (Interactive Tutorial)
- **Purpose**: Step-by-step walkthrough
- **Lines**: ~410
- **Sections**:
  1. Data preparation
  2. Parameter configuration
  3. Initial visualization
  4. Calibration demonstration
  5. Next steps and resources
- **Usage**: `source('example_calibration.R')`
- **Mode**: Interactive (requires user input)

## 📊 Data Files

### `data/observed_data.csv`
- **Purpose**: Template for field observations
- **Format**: CSV with headers
- **Required Columns**:
  - `Experiment` - Site/trial identifier
  - `Treatment` - Treatment code
  - `Date` - Observation date (YYYY-MM-DD)
  - `Variable` - DSSAT variable code
  - `Value` - Observed value
  - `SD` - Standard deviation (optional)
- **Example Variables**:
  - `HWAM` - Grain yield (kg/ha)
  - `CWAM` - Biomass (kg/ha)
  - `LAIX` - Max LAI
  - `ADAT` - Anthesis date
  - `MDAT` - Maturity date

## 🎯 Common Tasks

### Task 1: First Time Setup
```bash
# Read documentation
cat README_CALIBRATION.md | less
cat QUICK_START.md | less

# Verify setup
Rscript verify_setup.R

# Run tutorial
Rscript example_calibration.R
```

### Task 2: Basic Calibration
```r
# Configure
source("calibration_config.R")

# Edit settings (optional)
CROP_MODEL <- "MZCER048"
MAX_ITERATIONS <- 100

# Run
source("calibrate_dssat.R")
results <- main()
```

### Task 3: Custom Calibration
```r
# Load configuration
source("calibration_config.R")

# Customize parameters
CALIB_PARAMS <- list(
  P1 = c(min = 250, max = 320, init = 285),
  P5 = c(min = 700, max = 900, init = 800),
  G2 = c(min = 700, max = 900, init = 800)
)

# Custom weights
VARIABLE_WEIGHTS <- list(
  HWAM = 3.0,
  LAIX = 1.0
)

# Run
source("calibrate_dssat.R")
results <- main()
```

### Task 4: Batch Processing
```r
source("calibration_config.R")
source("calibrate_dssat.R")

cultivars <- c("Cult_A", "Cult_B", "Cult_C")
all_results <- list()

for (cult in cultivars) {
  CULTIVAR_NAME <- cult
  all_results[[cult]] <- main()
}

# Save combined results
saveRDS(all_results, "all_calibration_results.rds")
```

## 🔍 Troubleshooting Index

### Installation Issues
- **R packages not installing**: See QUICK_START.md → Prerequisites
- **CroPlotR not found**: See QUICK_START.md → Step 1
- **DSSAT not found**: See QUICK_START.md → Step 2

### Configuration Issues
- **Wrong crop model**: Edit `calibration_config.R` → CROP_MODEL
- **Bad parameter ranges**: Edit `calibration_config.R` → CALIB_PARAMS
- **Wrong data path**: Check DATA_DIR in `calibration_config.R`

### Runtime Issues
- **Calibration not converging**: See DSSAT_CALIBRATION_README.md → Troubleshooting
- **DSSAT errors**: Check dssat_helpers.R functions
- **Poor fit**: See DSSAT_CALIBRATION_README.md → Best Practices

### Output Issues
- **No plots generated**: Check PLOTS_DIR permissions
- **Missing statistics**: Check CroPlotR installation
- **Report not created**: Check OUTPUT_DIR exists

## 📈 Feature Index

### Supported Features

#### Crop Models
- ✅ CERES: Maize, Wheat, Rice, Barley, Sorghum, Millet
- ✅ CROPGRO: Soybean, Peanut, Bean, Chickpea, Cotton, Tomato
- ✅ Custom models (with parameter configuration)

#### Optimization Methods
- ✅ L-BFGS-B (bounded quasi-Newton)
- ✅ Nelder-Mead (simplex)
- ✅ SANN (simulated annealing)
- ✅ Custom objective functions

#### Statistical Metrics
- ✅ 40+ metrics via CroPlotR
- ✅ R², RMSE, nRMSE, rRMSE, MAE
- ✅ EF, Bias, FVU, d-index
- ✅ Component analysis (systematic/unsystematic error)

#### Visualization
- ✅ Time-series plots (dynamic)
- ✅ Scatter plots (1:1)
- ✅ Statistical comparison charts
- ✅ Error bars and confidence intervals
- ✅ Multiple export formats (PNG, PDF)

#### Data Handling
- ✅ Multi-site calibration
- ✅ Multi-season calibration
- ✅ Multiple variables
- ✅ Weighted objectives
- ✅ Cross-validation support (planned)

## 🎓 Learning Path

### Beginner (0-2 hours)
1. Read `README_CALIBRATION.md` (15 min)
2. Follow `QUICK_START.md` (20 min)
3. Run `verify_setup.R` (5 min)
4. Execute `example_calibration.R` (30 min)
5. Try with example data (30 min)

### Intermediate (2-5 hours)
1. Read `DSSAT_CALIBRATION_README.md` (30 min)
2. Prepare your own data (60 min)
3. Configure for your crop (30 min)
4. Run first calibration (60 min)
5. Analyze results (60 min)

### Advanced (5+ hours)
1. Review `FILE_SUMMARY.md` (30 min)
2. Study `dssat_helpers.R` (60 min)
3. Customize objective function (120 min)
4. Implement sensitivity analysis (120 min)
5. Develop custom workflows (variable)

## 🔗 External Resources

### DSSAT
- Official Site: https://dssat.net/
- Documentation: https://dssat.net/dssat-documentation
- Download: https://dssat.net/download
- Support: https://dssat.net/support
- Forum: https://dssat.net/forum

### CroPlotR
- GitHub: https://github.com/SticsRPacks/CroPlotR
- Documentation: https://sticsrpacks.github.io/CroPlotR/
- Issues: https://github.com/SticsRPacks/CroPlotR/issues

### R Resources
- R Project: https://www.r-project.org/
- CRAN: https://cran.r-project.org/
- RStudio: https://posit.co/download/rstudio-desktop/

## 📞 Getting Help

### For Different Issues

#### Script Errors
1. Check `verify_setup.R` output
2. Review error messages in console
3. Check file paths and permissions
4. Verify R package versions

#### DSSAT Issues
1. Verify DSSAT_DIR is correct
2. Check DSSAT input files
3. Validate experiment file format
4. Review DSSAT documentation

#### CroPlotR Issues
1. Check CroPlotR installation
2. Verify data format compatibility
3. Review CroPlotR documentation
4. Check GitHub issues

#### Statistical Questions
1. See DSSAT_CALIBRATION_README.md → Understanding Output
2. Review CroPlotR statistics documentation
3. Consult calibration literature
4. Check parameter biological meaning

## 📝 Quick Command Reference

```r
# Setup verification
source("verify_setup.R")

# Load configuration
source("calibration_config.R")

# Load helpers
source("dssat_helpers.R")

# Run tutorial
source("example_calibration.R")

# Run calibration
source("calibrate_dssat.R")
results <- main()

# View results
print(results$calibration$parameters)
print(results$report$statistics)

# Access plots
results$report$plots$scatter
results$report$plots$dynamic

# Save additional plots
library(CroPlotR)
save_plot_png(results$report$plots$scatter, "my_plots", "_scatter")
```

## 📦 Package Contents Summary

- **Total Scripts**: 5 R scripts
- **Total Documentation**: 5 Markdown files
- **Total Lines of Code**: ~2,400+
- **Total Documentation**: ~2,500+ lines
- **Example Datasets**: 1
- **Supported Crops**: 12+
- **Statistical Metrics**: 40+
- **Plot Types**: 3+

## ✅ Completion Checklist

Before running calibration, ensure:

- [ ] R version ≥ 4.0 installed
- [ ] Required R packages installed (dplyr, tidyr, ggplot2)
- [ ] CroPlotR package installed
- [ ] DSSAT installed and path configured
- [ ] All script files present
- [ ] Documentation reviewed
- [ ] Observed data prepared
- [ ] Configuration file edited
- [ ] Setup verification passed
- [ ] Tutorial completed (optional)

## 🎯 Next Steps

1. **If new to calibration**: Start with `README_CALIBRATION.md`
2. **If ready to calibrate**: Follow `QUICK_START.md`
3. **If need reference**: Use `DSSAT_CALIBRATION_README.md`
4. **If want to learn**: Run `example_calibration.R`
5. **If troubleshooting**: Check specific sections above

---

**Last Updated**: 2026-01-01

**Status**: ✅ Complete and Ready

**Maintained by**: DSSAT Calibration Framework Team

**Built with**: R + DSSAT + CroPlotR

# DSSAT Calibration Script

## Overview

This script provides a comprehensive framework for calibrating DSSAT (Decision Support System for Agrotechnology Transfer) crop models using observed experimental data. It integrates with the CroPlotR package for visualization and statistical analysis of calibration results.

## Features

- **Automated Parameter Optimization**: Uses R's optimization algorithms to find best-fit cultivar parameters
- **Multiple Crop Models**: Supports various DSSAT crop models (Maize, Wheat, Rice, etc.)
- **Comprehensive Reporting**: Generates detailed reports with statistics and visualizations
- **CroPlotR Integration**: Leverages CroPlotR for professional-quality plots and statistics
- **Flexible Configuration**: Easy-to-modify parameters and settings

## Prerequisites

### Required Software

1. **DSSAT** (Version 4.8 or later)
   - Download from: https://dssat.net/
   - Install and note the installation directory

2. **R** (Version 4.0 or later)
   - Download from: https://www.r-project.org/

3. **Required R Packages**:
   ```r
   install.packages(c("dplyr", "tidyr", "ggplot2"))
   
   # Install CroPlotR
   remotes::install_github("SticsRPacks/CroPlotR@*release")
   ```

### Optional (for full DSSAT integration)

- **DSSAT-R package** (if available) for direct R-DSSAT interface
- Alternative: Use system calls to DSSAT executables

## Directory Structure

```
workspace/
├── calibrate_dssat.R          # Main calibration script
├── data/                       # Input data directory
│   ├── observed_data.csv      # Observed experimental data
│   └── experiment.MZX         # DSSAT experiment file
└── calibration_output/         # Output directory (created automatically)
    ├── plots/                  # Generated plots
    ├── statistics/             # Statistical analysis
    ├── calibrated_parameters.csv
    └── calibration_report.txt
```

## Quick Start

### 1. Prepare Your Data

Create or modify `data/observed_data.csv` with your observed data:

```csv
Experiment,Treatment,Date,Variable,Value,SD
EXP1,T1,2023-06-15,HWAM,8500,450
EXP1,T1,2023-06-15,CWAM,16000,800
EXP1,T2,2023-06-20,HWAM,9200,520
```

**Column Descriptions**:
- `Experiment`: Unique identifier for the experiment/field trial
- `Treatment`: Treatment identifier (e.g., irrigation level, fertilizer rate)
- `Date`: Date of observation (YYYY-MM-DD format)
- `Variable`: DSSAT variable code (see Variable Codes section)
- `Value`: Observed value
- `SD`: Standard deviation (optional, for error bars in plots)

### 2. Configure DSSAT Path

Set the DSSAT installation directory:

**Option A: Environment Variable**
```bash
export DSSAT_DIR="/path/to/dssat"
```

**Option B: Modify Script**
Edit `calibrate_dssat.R` and change:
```r
DSSAT_DIR <- "/path/to/dssat"
```

### 3. Configure Crop Model

Edit `calibrate_dssat.R` to select your crop model:

```r
CROP_MODEL <- "MZCER048"  # Maize CERES
# Other options:
# "WHCER048"  # Wheat CERES
# "BACER048"  # Barley CERES
# "RICER048"  # Rice CERES
# "SBGRO048"  # Soybean CROPGRO
```

### 4. Configure Parameters to Calibrate

Modify the `CALIB_PARAMS` list based on your crop model:

#### Example for CERES-Maize:
```r
CALIB_PARAMS <- list(
  P1 = c(min = 200, max = 350, init = 280),      # Thermal time (°C·d)
  P2 = c(min = 0.1, max = 1.0, init = 0.5),      # Photoperiod sensitivity
  P5 = c(min = 600, max = 1000, init = 800),     # Grain filling duration (°C·d)
  G2 = c(min = 600, max = 1000, init = 800),     # Maximum kernels/plant
  G3 = c(min = 6, max = 12, init = 9),           # Kernel filling rate (mg/day)
  PHINT = c(min = 35, max = 55, init = 45)       # Phylochron interval (°C·d)
)
```

#### Example for CERES-Wheat:
```r
CALIB_PARAMS <- list(
  P1V = c(min = 0, max = 50, init = 20),         # Vernalization requirement (days)
  P1D = c(min = 0, max = 100, init = 50),        # Photoperiod sensitivity (%)
  P5 = c(min = 400, max = 800, init = 600),      # Grain filling duration (°C·d)
  G1 = c(min = 15, max = 35, init = 25),         # Kernel number coefficient
  G2 = c(min = 30, max = 60, init = 45),         # Kernel weight (mg)
  G3 = c(min = 1, max = 5, init = 2.5),          # Stem weight coefficient
  PHINT = c(min = 75, max = 120, init = 95)      # Phylochron interval (°C·d)
)
```

### 5. Run Calibration

**From Command Line:**
```bash
Rscript calibrate_dssat.R
```

**From R Console:**
```r
source("calibrate_dssat.R")
main()
```

## Variable Codes

Common DSSAT output variables for calibration:

| Code | Description | Unit |
|------|-------------|------|
| HWAM | Grain yield | kg/ha |
| CWAM | Total above-ground biomass | kg/ha |
| LAIX | Maximum leaf area index | m²/m² |
| GNAM | Grain N content | kg/ha |
| CNAM | Canopy N content | kg/ha |
| ADAT | Anthesis date | Days after planting (DAP) |
| MDAT | Maturity date | DAP |
| HWUM | Grain yield per unit | g/m² |
| H#AM | Harvest product number | #/m² |
| EDAT | Emergence date | DAP |

## Optimization Methods

The script supports multiple optimization algorithms:

### L-BFGS-B (Default)
```r
OPTIMIZATION_METHOD <- "L-BFGS-B"
```
- **Best for**: Continuous parameters with bounds
- **Advantages**: Fast convergence, handles bounds well
- **Use when**: You have reasonable parameter ranges

### Nelder-Mead
```r
OPTIMIZATION_METHOD <- "Nelder-Mead"
```
- **Best for**: Noisy objective functions
- **Advantages**: Robust, derivative-free
- **Use when**: Gradient information unavailable

### SANN (Simulated Annealing)
```r
OPTIMIZATION_METHOD <- "SANN"
```
- **Best for**: Global optimization with many local minima
- **Advantages**: Explores parameter space thoroughly
- **Use when**: Risk of local optima is high

## Output Files

### 1. Calibrated Parameters (`calibrated_parameters.csv`)
Contains final optimized parameter values with initial values and bounds.

### 2. Statistics (`statistics/calibration_statistics.csv`)
Comprehensive statistical metrics including:
- R² (coefficient of determination)
- RMSE (Root Mean Square Error)
- nRMSE (normalized RMSE)
- EF (Modeling Efficiency)
- Bias, MAE, and more

### 3. Plots (`plots/`)
- **Dynamic plots**: Time series comparisons of observed vs. simulated
- **Scatter plots**: 1:1 plots showing agreement between observed and simulated
- **Statistics plots**: Visual comparison of statistical metrics

### 4. Calibration Report (`calibration_report.txt`)
Text summary with all key information, parameters, and statistics.

## Advanced Usage

### Multiple Experiments

To calibrate across multiple experiments, add all data to `observed_data.csv`:

```csv
Experiment,Treatment,Date,Variable,Value,SD
Field_A,N100,2023-06-15,HWAM,8500,450
Field_A,N100,2023-06-15,CWAM,16000,800
Field_B,N150,2023-06-20,HWAM,9200,520
Field_B,N150,2023-06-20,CWAM,17500,900
```

### Custom Objective Function

Modify `objective_function()` to use different metrics:

```r
# Example: Use weighted RMSE
objective_function <- function(params, obs_data, experiment_file) {
  sim_results <- run_dssat_model(params, experiment_file)
  
  # Define weights for different variables
  weights <- list(
    HWAM = 2.0,   # Higher weight for yield
    CWAM = 1.0,
    LAIX = 1.5
  )
  
  weighted_rmse <- 0
  for (var in names(weights)) {
    obs_vals <- obs_data$Value[obs_data$Variable == var]
    sim_vals <- sim_results$summary$Value[sim_results$summary$Variable == var]
    
    if (length(sim_vals) > 0 && length(obs_vals) > 0) {
      rmse <- sqrt(mean((obs_vals - sim_vals[1])^2))
      weighted_rmse <- weighted_rmse + weights[[var]] * rmse
    }
  }
  
  return(weighted_rmse / sum(unlist(weights)))
}
```

### Parallel Processing

For faster calibration with many iterations, consider parallel processing:

```r
library(parallel)
library(foreach)
library(doParallel)

# Setup parallel backend
cl <- makeCluster(detectCores() - 1)
registerDoParallel(cl)

# Modify optimization to use parallel evaluation
# (Implementation depends on specific optimization needs)

stopCluster(cl)
```

### Sensitivity Analysis

After calibration, perform sensitivity analysis:

```r
# Vary each parameter while holding others constant
sensitivity_results <- list()

for (param_name in names(calib_results$parameters)) {
  base_params <- calib_results$parameters
  param_range <- seq(
    CALIB_PARAMS[[param_name]]["min"],
    CALIB_PARAMS[[param_name]]["max"],
    length.out = 20
  )
  
  responses <- numeric(length(param_range))
  
  for (i in seq_along(param_range)) {
    test_params <- base_params
    test_params[param_name] <- param_range[i]
    
    sim <- run_dssat_model(test_params, experiment_file)
    responses[i] <- sim$summary$Value[sim$summary$Variable == "HWAM"]
  }
  
  sensitivity_results[[param_name]] <- data.frame(
    parameter_value = param_range,
    response = responses
  )
}

# Plot sensitivity
library(ggplot2)
for (param in names(sensitivity_results)) {
  p <- ggplot(sensitivity_results[[param]], aes(x = parameter_value, y = response)) +
    geom_line() +
    labs(title = paste("Sensitivity:", param),
         x = param,
         y = "Yield (HWAM)")
  print(p)
}
```

## Troubleshooting

### Issue: DSSAT not found
**Solution**: 
- Verify DSSAT installation path
- Set `DSSAT_DIR` environment variable correctly
- Check that DSSAT executable exists in the specified directory

### Issue: Observed data not loading
**Solution**:
- Check CSV file format (comma-separated, proper headers)
- Ensure Date column is in YYYY-MM-DD format
- Verify file path in `DATA_DIR`

### Issue: Calibration not converging
**Solution**:
- Increase `MAX_ITERATIONS`
- Adjust parameter bounds (make them wider or narrower)
- Try different optimization method (e.g., SANN for global search)
- Check observed data quality
- Review initial parameter values

### Issue: Poor fit after calibration
**Solution**:
- Review parameter bounds (may be too restrictive)
- Check that correct crop model is selected
- Verify DSSAT input files (weather, soil) are accurate
- Consider calibrating additional parameters
- Check for data errors in observed values

## Integration with DSSAT Files

### Required DSSAT Input Files

1. **Experiment File** (.MZX, .WHX, etc.)
   - Contains experimental design
   - Management practices
   - Treatment specifications

2. **Weather File** (.WTH)
   - Daily weather data
   - Required variables: solar radiation, Tmax, Tmin, rainfall

3. **Soil File** (.SOL)
   - Soil profile information
   - Physical and chemical properties

4. **Cultivar File** (.CUL)
   - Cultivar genetic coefficients
   - This is what gets updated during calibration

### Updating DSSAT Files with Calibrated Parameters

After calibration, update your cultivar file:

```r
# Read calibrated parameters
params <- read.csv("calibration_output/calibrated_parameters.csv")

# Update cultivar file (implementation depends on file format)
# You may need to manually edit the .CUL file or use DSSAT tools
```

## Best Practices

1. **Start with good initial values**: Use values from literature or similar cultivars
2. **Use appropriate bounds**: Not too wide (slow convergence) or too narrow (miss optimum)
3. **Calibrate with multiple seasons/locations**: Improves parameter generalizability
4. **Validate independently**: Test calibrated parameters on data not used for calibration
5. **Document everything**: Keep records of data sources, assumptions, and decisions
6. **Check parameter correlations**: Some parameters may be highly correlated
7. **Use multiple objective functions**: Compare results from different metrics

## References

- DSSAT Official Website: https://dssat.net/
- DSSAT Documentation: https://dssat.net/dssat-documentation
- CroPlotR Package: https://github.com/SticsRPacks/CroPlotR
- Jones et al. (2003). The DSSAT cropping system model. European Journal of Agronomy, 18(3-4), 235-265.

## Citation

If you use this script in your research, please cite:

- The DSSAT model: Jones, J.W., et al. (2003). The DSSAT cropping system model. European Journal of Agronomy, 18(3-4), 235-265.
- The CroPlotR package: Use `citation("CroPlotR")` in R

## Support

For issues related to:
- **This script**: Create an issue in the repository
- **DSSAT software**: Visit https://dssat.net/support
- **CroPlotR package**: Visit https://github.com/SticsRPacks/CroPlotR/issues

## License

This script is provided as-is under the same license as the CroPlotR package.

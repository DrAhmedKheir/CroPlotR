# Sakha95 Wheat Cultivar Calibration for DSSAT CERES-Wheat

Multi-site, multi-year calibration of genetic coefficients for the Egyptian Sakha95 wheat cultivar using DSSAT CERES-Wheat model with CroptimizR optimization framework and comprehensive visualization tools.

## 📋 Overview

This repository contains R scripts for calibrating the Sakha95 wheat cultivar parameters in DSSAT CERES-Wheat using 41 years (1980-2021) of field observations from two locations in Egypt (Gemiza and Sids). The calibration achieved **69.2% RMSE improvement** using Nelder-Mead optimization.

## ✨ Key Features

- **Real DSSAT Integration**: Direct execution of DSSAT model (not mock simulation)
- **Multi-Site Calibration**: 50 treatment-location combinations across 2 sites
- **Multi-Year Data**: 41 years of field observations (185 data points)
- **7 Genetic Coefficients**: P1V, P1D, P5, G1, G2, G3, PHINT
- **Robust Optimization**: Nelder-Mead algorithm with bounded parameters
- **Publication-Ready Visualizations**: 10+ high-quality plots
- **Comprehensive Documentation**: Step-by-step guides and troubleshooting

## 🎯 Results

### Calibration Performance
- **RMSE Improvement**: 69.2% (10,707 → 3,295 kg/ha)
- **Runtime**: ~24 minutes (103 DSSAT evaluations)
- **Convergence**: Successfully optimized all 7 parameters

### Optimized Parameters
| Parameter | Initial | Calibrated | Change |
|-----------|---------|------------|--------|
| P1V (days) | 16.0 | 2.2 | -86.0% |
| P1D (%) | 74.6 | 50.2 | -32.7% |
| P5 (°C·d) | 660 | 776 | +17.6% |
| G1 | 47.0 | 30.0 | -36.2% |
| G2 (mg) | 80.0 | 108.5 | +35.6% |
| G3 (g) | 0.8 | 1.7 | +116.1% |
| PHINT (°C·d) | 131.0 | 107.6 | -17.8% |

## 📁 Repository Contents

```
.
├── calibrate_Sakha95_FINAL_CORRECTED.R       # Main calibration script
├── visualize_Sakha95_calibration.R           # Visualization script
├── CALIBRATION_COMPLETE_DOCUMENTATION.md     # Detailed calibration guide
├── VISUALIZATION_DOCUMENTATION.md            # Visualization guide
├── data/
│   └── Sakha95_observed_data.csv            # Field observations
├── results/                                  # Output directory (created by scripts)
│   ├── plots/                               # Generated visualizations
│   ├── calibrated_parameters.csv            # Parameter comparison
│   ├── statistics_summary.csv               # Performance metrics
│   └── calibration.RData                    # R results object
└── docs/                                     # Additional documentation
    ├── QUICK_START_GUIDE.md
    ├── TROUBLESHOOTING.md
    └── FUNCTION_SIGNATURE_FIX.md
```

## 🚀 Quick Start

### Prerequisites

**Software:**
- R (≥ 4.0)
- DSSAT 4.8 installed at `C:/DSSAT48`
- DSSAT-wrapper R functions ([DrAhmedKheir/DSSAT-wrapper](https://github.com/DrAhmedKheir/DSSAT-wrapper))

**R Packages:**
```r
install.packages(c("nloptr", "dplyr", "ggplot2", "tidyr", "gridExtra"))
```

**Data Files Required:**
- `GMZA2001.WHX` (23 treatments) in `C:/DSSAT48/Wheat/`
- `GMZA2001.WHA` (harvest observations)
- `SIDS2001.WHX` (27 treatments)
- `SIDS2001.WHA` (harvest observations)
- Weather files: `GMZA*.WTH`, `SIDS*.WTH` in `C:/DSSAT48/Weather/`
- Cultivar file: `WHCER048.CUL` in `C:/DSSAT48/Genotype/`

### Installation

1. **Clone this repository:**
```bash
git clone https://github.com/YOUR_USERNAME/Sakha95-DSSAT-Calibration.git
cd Sakha95-DSSAT-Calibration
```

2. **Install DSSAT-wrapper:**
```r
# Download DSSAT_wrapper.R and read_obs.R from:
# https://github.com/DrAhmedKheir/DSSAT-wrapper
# Place in your working directory or R/ subdirectory
```

3. **Set working directory:**
```r
setwd("path/to/Sakha95-DSSAT-Calibration")
```

### Running Calibration

```r
# 1. Run calibration (takes ~25 minutes)
source("calibrate_Sakha95_FINAL_CORRECTED.R")

# 2. Generate visualizations (takes ~25 minutes)
source("visualize_Sakha95_calibration.R")

# 3. Review results
list.files("Sakha95_CORRECTED_results/plots/")
```

## 📊 Outputs

### Calibration Results
- **calibrated_parameters.csv**: Parameter comparison table
- **calibration.RData**: Complete R results object

### Visualizations
- **Scatter plots**: Observed vs simulated (initial & calibrated)
- **Residual plots**: Error analysis by variable
- **Improvement charts**: RMSE reduction and R² gains
- **Parameter comparison**: Visual changes in coefficients

### Statistics
- **statistics_summary.csv**: RMSE, R², Bias, MAE, EF metrics
- **simulation_comparison_data.csv**: Raw comparison data

## 🔬 Methodology

### Calibration Approach
1. **Model**: DSSAT CERES-Wheat (WHCER048)
2. **Optimizer**: Nelder-Mead simplex algorithm (nloptr)
3. **Objective**: Minimize RMSE across multiple variables
4. **Variables**: HWAM (yield), ADAT (anthesis), H#AM, HWUM
5. **Validation**: Multi-site, multi-year cross-validation

### Key Technical Features
- **Cultivar Recognition**: Uses VRNAME ("Sakha95") instead of VAR-NAME
- **Date Masking**: `sit_var_dates_mask` ensures obs/sim alignment
- **End-of-Season Comparison**: Matches harvest observations with final simulation output
- **Robust Error Handling**: Multiple fallback mechanisms

## 📖 Documentation

### Complete Guides
- [**Calibration Documentation**](CALIBRATION_COMPLETE_DOCUMENTATION.md): Full scientific and technical guide
- [**Visualization Documentation**](VISUALIZATION_DOCUMENTATION.md): Plot generation and interpretation
- [**Quick Start Guide**](docs/QUICK_START_GUIDE.md): Get running in 5 minutes
- [**Troubleshooting**](docs/TROUBLESHOOTING.md): Common issues and solutions

### Key Insights
- Parameter P1V shows Sakha95 is spring-type wheat (2.2 days vernalization)
- Low photoperiod sensitivity (P1D = 50.2%) typical for Egyptian varieties
- Large kernel weight (G2 = 108.5 mg) indicates quality characteristics
- Long grain filling (P5 = 776°C·d) contributes to high yield potential

## 🎓 Citation

If you use this work in your research, please cite:

```bibtex
@software{sakha95_calibration,
  title = {Sakha95 Wheat Cultivar Calibration for DSSAT CERES-Wheat},
  author = {[Your Name]},
  year = {2026},
  url = {https://github.com/YOUR_USERNAME/Sakha95-DSSAT-Calibration}
}
```

### Related Publications
- Hoogenboom, G., et al. (2019). The DSSAT crop modeling ecosystem. *Advances in Crop Modeling*.
- Wallach, D., et al. (2021). How well do crop models predict phenology. *European Journal of Agronomy*.
- Kheir, A. (2024). DSSAT-wrapper for CroptimizR. GitHub repository.

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

### Areas for Contribution
- Validation with independent datasets
- Sensitivity analysis implementation
- Additional visualization options
- Support for other wheat cultivars
- Integration with other optimization algorithms

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **DSSAT Development Team** for the crop modeling platform
- **Dr. Ahmed Kheir** for DSSAT-wrapper R functions
- **CroptimizR Team** for optimization framework concepts
- **Egyptian Agricultural Research Center** for field data

## 📧 Contact

- **Author**: [Your Name]
- **Email**: your.email@example.com
- **Institution**: [Your Institution]
- **Issues**: Please use the GitHub Issues tracker

## 🔗 Related Projects

- [DSSAT Official](https://dssat.net/)
- [DSSAT-wrapper by Dr. Ahmed Kheir](https://github.com/DrAhmedKheir/DSSAT-wrapper)
- [CroptimizR](https://github.com/SticsRPacks/CroptimizR)
- [CroPlotR](https://github.com/SticsRPacks/CroPlotR)

## 📊 Repository Stats

![GitHub last commit](https://img.shields.io/github/last-commit/YOUR_USERNAME/Sakha95-DSSAT-Calibration)
![GitHub repo size](https://img.shields.io/github/repo-size/YOUR_USERNAME/Sakha95-DSSAT-Calibration)
![GitHub language count](https://img.shields.io/github/languages/count/YOUR_USERNAME/Sakha95-DSSAT-Calibration)
![GitHub top language](https://img.shields.io/github/languages/top/YOUR_USERNAME/Sakha95-DSSAT-Calibration)

---

⭐ **Star this repository if it helped your research!** ⭐

**Keywords**: DSSAT, wheat, calibration, CERES-Wheat, Sakha95, Egypt, genetic coefficients, crop modeling, parameter estimation, CroptimizR, nloptr, Nelder-Mead

# 🚀 Sakha95 CroptimizR Calibration - Quick Start Guide

**Print this page for quick reference!**

---

## ⚡ 5-Minute Setup

### 1. Download Files (2 min)
```
From Cursor workspace → Download:
✓ calibrate_Sakha95_CroptimizR.R
✓ README_CroptimizR_CALIBRATION.md
✓ FINAL_DELIVERY_SUMMARY.md
✓ QUICK_START_GUIDE.md

Save all to: C:\DSSAT48\
```

### 2. Get DSSAT Wrapper (2 min)
```
Go to: https://github.com/DrAhmedKheir/DSSAT-wrapper
Click: Code → Download ZIP
Extract: R/DSSAT_wrapper.R
Save to: C:\DSSAT48\DSSAT_wrapper\DSSAT_wrapper.R
```

### 3. Run Script (1 min)
```r
# In RStudio:
setwd("C:/DSSAT48")
source("calibrate_Sakha95_CroptimizR.R")
```

**✅ Setup complete! Follow on-screen instructions.**

---

## 🎯 Your Data Summary

| Item | Value |
|------|-------|
| **Cultivar** | Sakha95 (SK0010) |
| **Locations** | Gemiza (26 treatments), Sids (33 treatments) |
| **Years** | 1980-2021 (41 years) |
| **Observations** | 218 total |
| **Variables** | HWAM, H#AM, HWUM, ADAT, MDAT |
| **Parameters** | P1V, P1D, P5, G1, G2, G3, PHINT |

---

## 📝 Essential File Paths

```r
# Main files
DSSAT_DIR     <- "C:/DSSAT48"
WORK_DIR      <- "C:/DSSAT48"
DATA_DIR      <- "C:/DSSAT48/data"
OUTPUT_DIR    <- "C:/DSSAT48/Sakha95_CroptimizR_output"

# Wrapper
WRAPPER_FILE  <- "C:/DSSAT48/DSSAT_wrapper/DSSAT_wrapper.R"

# Data
OBS_DATA      <- "C:/DSSAT48/data/Sakha95_observed_data.csv"

# DSSAT files
CULTIVAR_FILE <- "C:/DSSAT48/Genotype/WHCER048.CUL"
DSSAT_EXE     <- "C:/DSSAT48/DSCSM048.EXE"
```

---

## 🔧 Configuration

### Parameters to Calibrate

```r
P1V    = c(min=0,   max=45,  init=25)   # Vernalization (days)
P1D    = c(min=40,  max=90,  init=70)   # Photoperiod (%)
P5     = c(min=450, max=650, init=550)  # Grain filling (°C·d)
G1     = c(min=18,  max=30,  init=24)   # Kernel number
G2     = c(min=38,  max=52,  init=45)   # Kernel weight (mg)
G3     = c(min=1.5, max=3.0, init=2.2)  # Stem weight (g)
PHINT  = c(min=85,  max=105, init=95)   # Phylochron (°C·d)
```

### Calibration Settings

```r
method      = "simplex"        # Nelder-Mead optimization
max_iter    = 500              # Maximum iterations
criterion   = likelihood_log_ciidn  # Objective function
```

---

## 🎯 Critical Steps

### Before Running Calibration

☐ **Verify DSSAT works**
```r
# Test DSSAT installation
file.exists("C:/DSSAT48/DSCSM048.EXE")  # Should be TRUE
```

☐ **Check data loaded**
```r
# After running setup script
nrow(obs_raw)  # Should be 218
length(obs_list)  # Should be ~59
```

☐ **Source wrapper**
```r
source("C:/DSSAT48/DSSAT_wrapper/DSSAT_wrapper.R")
exists("DSSAT_wrapper")  # Should be TRUE
```

### During Calibration

Monitor progress:
```
Iteration 1: criterion = 0.523
Iteration 10: criterion = 0.412
Iteration 20: criterion = 0.356
...
```

**✓ Good**: Criterion decreases  
**✗ Bad**: Criterion increases or stays constant

### After Calibration

Review results:
```r
# Parameter changes
param_results <- data.frame(
  Parameter = names(calib_results$final_values),
  Initial = param_init,
  Calibrated = calib_results$final_values,
  Change_Percent = ((calib_results$final_values - param_init) / param_init) * 100
)
print(param_results)
```

**✓ Good**: Parameters change 5-30%  
**✗ Bad**: Parameters change <1% or hit bounds

---

## 📊 Quick Visualization

### After calibration completes:

```r
# Get final simulation
sim_final <- DSSAT_wrapper(
  param_values = calib_results$final_values,
  sit_names = all_situations,
  model_options = model_options
)

# Dynamic plots
plot(sim_final, obs = obs_list, type = "dynamic")

# Scatter plots
plot(sim_final, obs = obs_list, type = "scatter", all_situations = TRUE)

# Statistics
summary(sim_final, obs = obs_list, all_situations = TRUE)
```

---

## ⏱️ Expected Timelines

| Phase | Duration | What Happens |
|-------|----------|--------------|
| **Setup** | 10-30 min | Install packages, download files |
| **Calibration** | 2-6 hours | DSSAT runs ~500 times |
| **Results** | 30-60 min | Generate plots, review statistics |
| **Total** | 3-7 hours | Complete professional calibration |

**💡 Tip**: Run overnight or during lunch!

---

## ⚠️ Common Issues & Fixes

### Issue: "DSSAT_wrapper not found"
```r
# Fix:
source("C:/DSSAT48/DSSAT_wrapper/DSSAT_wrapper.R")
```

### Issue: "Cannot install CroptimizR"
```r
# Fix: Install dependencies first
install.packages(c("nloptr", "hydroGOF", "DiceDesign"))
remotes::install_github("SticsRPacks/CroptimizR@*release")
```

### Issue: "Observed data has wrong format"
```r
# Check structure:
str(obs_list)
# Should be: List of 59 data frames
# Each with: Date + variable columns
```

### Issue: "Calibration not converging"
```r
# Try:
# 1. Reduce max iterations for testing
optim_options = list(maxeval = 50)

# 2. Adjust parameter bounds
# 3. Start with fewer situations
# 4. Check DSSAT runs successfully
```

---

## 📈 Success Metrics

Your calibration is good when:

| Metric | Target | Your Value |
|--------|--------|------------|
| **R²** | > 0.70 | _____ |
| **nRMSE** | < 20% | _____ |
| **Bias** | Near 0 | _____ |
| **Parameter Change** | 5-30% | _____ |
| **Convergence** | Yes | _____ |

---

## 💾 Save Your Results

```r
# Save everything
save(calib_results, sim_final, obs_list,
     file = file.path(output_dir, "calibration_complete.RData"))

# Later, load with:
load(file.path(output_dir, "calibration_complete.RData"))
```

---

## 🎨 Publication-Ready Plots

```r
# High-resolution plots
library(ggplot2)

p <- plot(sim_final, obs = obs_list, type = "scatter", all_situations = TRUE)

ggsave(filename = file.path(output_dir, "Figure1_scatter.png"),
       plot = p[[1]],
       width = 8, height = 6, dpi = 300, units = "in")

ggsave(filename = file.path(output_dir, "Figure1_scatter.pdf"),
       plot = p[[1]],
       width = 8, height = 6, units = "in")
```

---

## 📞 Help Resources

| Resource | Link |
|----------|------|
| **CroptimizR Docs** | https://sticsrpacks.github.io/CroptimizR/ |
| **CroPlotR Docs** | https://sticsrpacks.github.io/CroPlotR/ |
| **DSSAT Wrapper** | https://github.com/DrAhmedKheir/DSSAT-wrapper |
| **DSSAT Forum** | https://dssat.net/forum |

---

## ✅ Pre-Flight Checklist

**Print and check off before running:**

### Files & Setup
☐ Downloaded calibration script  
☐ Downloaded README  
☐ Downloaded DSSAT wrapper  
☐ Installed DSSAT 4.8  
☐ Installed R & RStudio  

### Data Verification
☐ Observed data file exists (218 obs)  
☐ Experiment files exist (GMZA2001.WHX, SIDS2001.WHX)  
☐ Weather files exist (.WHA)  
☐ Cultivar file has SK0010  

### Script Configuration
☐ All paths verified  
☐ All packages installed  
☐ DSSAT wrapper loaded  
☐ Data formatted correctly  
☐ Parameters configured  

### Ready to Calibrate!
☐ Test simulation successful  
☐ Calibration code uncommented  
☐ Output directory created  
☐ Time allocated (2-6 hours)  

---

## 🎉 You're All Set!

**Your 41 years of field data + Professional tools = Excellent calibration!**

**Next Step**: Run the script and follow on-screen instructions!

```r
source("C:/DSSAT48/calibrate_Sakha95_CroptimizR.R")
```

---

**Quick Start Guide v1.0** | January 2026 | Sakha95 Wheat Calibration

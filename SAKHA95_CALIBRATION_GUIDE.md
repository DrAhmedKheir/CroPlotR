# SAKHA95 WHEAT CALIBRATION - COMPLETE GUIDE

## 🌾 SAKHA95 MULTI-SITE CALIBRATION

**Cultivar**: Sakha95 (Code: SK0010)  
**Locations**: Gemiza (23 points) + Sids (27 points) = **50 total observations**  
**Model**: CERES-Wheat (WHCER048)  
**DSSAT**: C:\DSSAT48

---

## ✅ YOUR EXACT FILE PATHS (Pre-Configured)

```
C:\DSSAT48\
├── Genotype\
│   ├── WHCER048.CUL  ← Cultivar genetic coefficients (SK0010 = Sakha95)
│   ├── WHCER048.ECO  ← Ecotype coefficients
│   └── WHCER048.SPE  ← Species parameters
└── Wheat\
    ├── GMZA2001.WHX  ← Gemiza experiment (23 points)
    ├── GMZA2001.WHA  ← Gemiza weather data
    ├── SIDS2001.WHX  ← Sids experiment (27 points)
    └── SIDS2001.WHA  ← Sids weather data
```

---

## 🎯 WHAT YOU NEED TO DO (2 Steps)

### STEP 1: Fill in Your Observed Data ⚠️ CRITICAL

**File**: `data/Sakha95_observed_data.csv`

This file currently has **example template data**. You must replace it with your **actual 50 data points** from field measurements.

**Required format**:

```csv
Location,Experiment,Treatment,Date,Variable,Value,SD
Gemiza,GMZA2001,T1,2001-04-10,HWAM,6800,420
Gemiza,GMZA2001,T1,2001-04-10,CWAM,15500,920
```

**What you need**:

| Location | Experiment | # Points | Variables to Include |
|----------|------------|----------|---------------------|
| Gemiza   | GMZA2001   | 23       | HWAM, CWAM, LAIX, GNAM, ADAT, MDAT |
| Sids     | SIDS2001   | 27       | HWAM, CWAM, LAIX, GNAM, ADAT, MDAT |
| **TOTAL** |           | **50**   | Mix of treatments and dates |

**Variable Descriptions for Sakha95**:

| Code | Description | Typical Range | Unit |
|------|-------------|---------------|------|
| HWAM | Grain yield | 5,500-8,000 | kg/ha |
| CWAM | Biomass | 12,000-18,000 | kg/ha |
| LAIX | Max LAI | 4.5-6.5 | m²/m² |
| GNAM | Grain N | 120-180 | kg/ha |
| ADAT | Anthesis date | 80-95 | DAP |
| MDAT | Maturity date | 125-140 | DAP |

**Tips**:
- Include multiple treatments per location (N rates, irrigation, etc.)
- Spread observations across different dates
- Include standard deviations (SD) if available
- More variables = better calibration

---

### STEP 2: Run the Calibration

**From R Console**:
```r
source("calibrate_Sakha95_wheat.R")
main()
```

**From RStudio**:
1. Open `calibrate_Sakha95_wheat.R`
2. Click "Source" or press Ctrl+Shift+S
3. Or type: `main()`

**From Command Line**:
```cmd
cd path\to\workspace
Rscript calibrate_Sakha95_wheat.R
```

---

## 📊 WHAT THE SCRIPT DOES

### Phase 1: Verification (1 minute)
✓ Checks DSSAT installation at `C:\DSSAT48`  
✓ Verifies all 6 required files exist  
✓ Confirms Sakha95 (SK0010) in cultivar file  
✓ Loads your observed data  

### Phase 2: Calibration (5-15 minutes)
✓ Optimizes 7 genetic coefficients simultaneously  
✓ Uses data from both Gemiza and Sids  
✓ Runs iterative optimization (max 200 iterations)  
✓ Monitors convergence  

### Phase 3: Reporting (1-2 minutes)
✓ Generates performance statistics  
✓ Creates comparison plots  
✓ Produces detailed text report  
✓ Saves all results  

**Total Time**: ~7-18 minutes depending on your computer

---

## 📁 OUTPUT FILES

All saved to: `Sakha95_calibration_output/`

### Main Files:

1. **`Sakha95_calibration_report.txt`** ⭐ **READ THIS FIRST**
   - Complete calibration summary
   - Performance metrics (MAPE, RMSE)
   - Exact values to put in WHCER048.CUL
   - Step-by-step update instructions

2. **`Sakha95_calibrated_parameters.csv`**
   - Optimized genetic coefficients
   - Initial vs final values
   - Percent changes

3. **`Sakha95_obs_vs_sim.csv`**
   - Observed vs simulated comparison
   - Performance by location and variable
   - Error analysis

### Plots (`plots/` folder):

4. **`Sakha95_obs_vs_sim_scatter.png`**
   - Visual comparison of model fit
   - Separate panels for each location

5. **`Sakha95_error_by_variable.png`**
   - Error bars by variable and location
   - Shows which variables fit best

6. **`Sakha95_parameter_comparison.png`**
   - Before/after parameter values
   - Visual change representation

---

## 🎯 UNDERSTANDING RESULTS

### Performance Metrics

**MAPE (Mean Absolute Percent Error)**
- < 10% = **Excellent** ✓
- 10-15% = **Very Good** ✓
- 15-20% = **Good** ✓
- 20-30% = **Acceptable** ⚠
- > 30% = **Poor** ✗ (needs work)

**RMSE (Root Mean Square Error)**
- Lower is better
- Units depend on variable
- Compare across locations

### What to Check:

1. **Overall MAPE**: Should be < 20% for good calibration
2. **MAPE by Location**: Should be similar (Gemiza ≈ Sids)
3. **MAPE by Variable**: 
   - Yield (HWAM) most important
   - Phenology (ADAT, MDAT) should be close
4. **Parameter Changes**: Large changes (>50%) may indicate issues

---

## 🔧 UPDATING DSSAT

### Automatic Instructions

The calibration report (`Sakha95_calibration_report.txt`) contains:
- Exact file location: `C:\DSSAT48\Genotype\WHCER048.CUL`
- Exact cultivar code to find: `SK0010`
- **Exact values** formatted for copy-paste into .CUL file

### Manual Steps:

1. **Backup Original**
   ```
   Copy: C:\DSSAT48\Genotype\WHCER048.CUL
   To: C:\DSSAT48\Genotype\WHCER048_ORIGINAL.CUL
   ```

2. **Open File**
   - Use Notepad++ or Notepad
   - Open: `C:\DSSAT48\Genotype\WHCER048.CUL`

3. **Find Sakha95**
   - Press Ctrl+F
   - Search for: `SK0010`

4. **Update Coefficients**
   - Replace the 7 coefficient values
   - Report shows exact values to enter
   - Maintain column alignment (fixed-width format)

5. **Save File**

6. **Test in DSSAT**
   - Run a test simulation
   - Verify it runs without errors
   - Check outputs are reasonable

---

## 🔍 TROUBLESHOOTING

### Issue: "DSSAT directory not found"

**Fix**: 
- Verify `C:\DSSAT48` exists on your computer
- If DSSAT is elsewhere, edit line 129 in script:
  ```r
  DSSAT_DIR <- "C:/Your/Path/To/DSSAT"
  ```

---

### Issue: "Cultivar file not found"

**Fix**:
- Check `C:\DSSAT48\Genotype\WHCER048.CUL` exists
- DSSAT might be in `C:\DSSAT47` or `C:\DSSAT49`
- Update `DSSAT_DIR` accordingly

---

### Issue: "SK0010 not found in cultivar file"

**Fix**:
- Open `WHCER048.CUL`
- Search for "Sakha" or "Sakha95"
- If not present, you need to add it manually first
- Or use a different cultivar code that exists

---

### Issue: "Insufficient observed data"

**Fix**:
- You need at least 10 observations total
- Ideally 23 for Gemiza + 27 for Sids = 50 total
- Include at least: HWAM, ADAT, MDAT for each location

---

### Issue: "Poor calibration (high MAPE)"

**Possible causes**:
1. **Data quality**: Check for measurement errors
2. **Wrong treatments**: Verify treatment codes match
3. **Parameter ranges**: May need adjustment
4. **Weather data**: Ensure correct weather file
5. **Soil data**: Check soil parameters in .WHX files

**Solutions**:
1. Review observed data for outliers
2. Increase `MAX_ITERATIONS` (line 102) to 300
3. Widen parameter ranges (lines 72-80)
4. Try different optimization method (line 104)

---

### Issue: "Not converging"

**Fix 1**: Increase iterations
```r
MAX_ITERATIONS <- 300  # Line 102
```

**Fix 2**: Widen parameter bounds
```r
CALIB_PARAMS <- list(
  P1V = c(min = 0, max = 60, init = 25),  # Wider range
  P1D = c(min = 30, max = 100, init = 70),
  ...
)
```

**Fix 3**: Try different method
```r
OPTIMIZATION_METHOD <- "Nelder-Mead"  # Line 104
```

---

## 📚 GENETIC COEFFICIENT GUIDE

### P1V (Vernalization)
- **Range**: 0-45 days for Sakha95
- **Meaning**: Days of cold needed for development
- **Egyptian wheat**: Typically low (10-35) - spring types
- **Effect**: Higher = later flowering

### P1D (Photoperiod Sensitivity)
- **Range**: 40-90% for Sakha95
- **Meaning**: Sensitivity to day length
- **Egyptian wheat**: Moderate (50-85%)
- **Effect**: Higher = more delayed by short days

### P5 (Grain Filling Duration)
- **Range**: 450-650 °C·d
- **Meaning**: Heat accumulation for grain filling
- **Egyptian wheat**: 450-600 typical
- **Effect**: Higher = longer grain filling = higher yield potential

### G1 (Kernel Number)
- **Range**: 18-30
- **Meaning**: Kernels per unit canopy weight
- **Egyptian wheat**: 20-28 typical
- **Effect**: Higher = more kernels = higher yield potential

### G2 (Kernel Weight)
- **Range**: 38-52 mg
- **Meaning**: Individual kernel size
- **Egyptian wheat**: 40-50 typical
- **Effect**: Higher = larger kernels = higher yield

### G3 (Stem Weight)
- **Range**: 1.5-3.0 g
- **Meaning**: Stem biomass at maturity
- **Semi-dwarf wheat**: Lower values (1.5-2.5)
- **Effect**: Affects partitioning to grain

### PHINT (Phylochron)
- **Range**: 85-105 °C·d
- **Meaning**: Heat between leaf appearances
- **Egyptian wheat**: 85-105 typical
- **Effect**: Higher = slower leaf appearance = later maturity

---

## ✅ VALIDATION CHECKLIST

After calibration:

- [ ] MAPE < 20% overall
- [ ] MAPE similar for both locations
- [ ] Parameters within biological ranges
- [ ] Yield predictions reasonable
- [ ] Phenology dates make sense
- [ ] Backed up original .CUL file
- [ ] Updated .CUL file with new coefficients
- [ ] Tested in DSSAT (runs without error)
- [ ] Documented calibration details
- [ ] **Validated with independent data**

---

## 🎓 NEXT STEPS AFTER CALIBRATION

### 1. Immediate Validation
- Test on data NOT used for calibration
- Try different years from same locations
- Try completely different locations

### 2. Sensitivity Analysis
- Vary each parameter ±10%
- See which ones affect yield most
- Understand parameter interactions

### 3. Uncertainty Analysis
- Run bootstrap resampling
- Estimate parameter confidence intervals
- Assess prediction uncertainty

### 4. Documentation
- Save all calibration files
- Document data sources
- Record any assumptions made
- Note DSSAT version used

### 5. Application
- Use for yield prediction
- Test management scenarios
- Climate impact assessment
- Decision support

---

## 📞 SUPPORT

### Script Issues
- Check this README
- Review error messages
- Verify all paths correct
- Ensure data format matches template

### DSSAT Issues
- Website: https://dssat.net/
- Documentation: https://dssat.net/dssat-documentation
- Forum: https://dssat.net/forum

### Statistical Questions
- Review calibration report
- Check literature for typical values
- Consult with agronomists/modelers

---

## 📖 REFERENCES

### Sakha95 Information
- High-yielding Egyptian cultivar
- Released by ARC (Agricultural Research Center), Egypt
- Widely grown in Nile Delta and Middle Egypt
- Good disease resistance
- Suitable for optimal and late sowing

### Egyptian Wheat Calibration
- Typically requires P1V = 15-30 (low vernalization)
- P1D around 60-80 for Nile Delta conditions
- Growing season: November-April (140-150 days)
- Optimal sowing: Mid-November to early December

### DSSAT-Wheat
- Ritchie, J.T., & Otter, S. (1985). Description and performance of CERES-Wheat
- Jones et al. (2003). DSSAT cropping system model
- Hunt & Pararajasingham (1995). GENCALC: Software to facilitate calibration

---

## ✨ SUMMARY

**You have**:
- ✅ Complete calibration script (`calibrate_Sakha95_wheat.R`)
- ✅ Template for your data (`Sakha95_observed_data.csv`)
- ✅ This comprehensive guide
- ✅ All paths pre-configured for your setup

**You need**:
1. Fill in your 50 observed data points
2. Run the script
3. Update WHCER048.CUL with results

**Time required**:
- Data entry: 30-60 minutes
- Running script: 10-20 minutes
- Updating DSSAT: 5 minutes
- **Total**: ~1-2 hours for complete calibration

---

**Ready? Fill in your data and run the script! 🚀**

Version 1.0 | 2026-01-01 | Sakha95 Multi-Site Calibration

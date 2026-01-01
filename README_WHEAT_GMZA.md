# Wheat Calibration Script for GEMIZA Location - README

## 🌾 WHEAT CALIBRATION FOR GEMIZA, EGYPT (GMZA2001)

This is a **customized calibration script** specifically configured for your wheat experiment at **Gemiza location** using DSSAT CERES-Wheat model.

---

## 📋 YOUR CONFIGURATION

✅ **Already configured in the script:**
- **Location**: Gemiza, Egypt (GMZA)
- **DSSAT Directory**: `C:/Users/DELL/OneDrive/Desktop/originaldssat`
- **Experiment File**: `GMZA2001.WHX`
- **Weather File**: `GMZA2001.WHA`
- **Crop Model**: WHCER048 (CERES-Wheat)
- **Cultivar File**: WHCER048.CUL
- **Ecotype File**: WHCER048.ECO

---

## ⚠️ BEFORE RUNNING - 3 REQUIRED STEPS

### STEP 1: Update Cultivar Name (Line 40 in script)

Open `calibrate_wheat_GMZA2001.R` and change:

```r
CULTIVAR_NAME <- "IB0001"  # ⚠️ CHANGE THIS
```

To your actual cultivar name from WHCER048.CUL, for example:
```r
CULTIVAR_NAME <- "Sakha93"   # Egyptian wheat cultivar
# OR
CULTIVAR_NAME <- "Gemiza9"   # Egyptian wheat cultivar
# OR
CULTIVAR_NAME <- "Sids1"     # Egyptian wheat cultivar
# OR whatever cultivar name is in your .CUL file
```

**How to find your cultivar name:**
1. Open: `C:\Users\DELL\OneDrive\Desktop\originaldssat\Genotype\WHCER048.CUL`
2. Look in the first column for your cultivar code (e.g., "IB0488", "Sakha93", etc.)
3. Copy that exact name to the script

---

### STEP 2: Fill in Your Observed Data

Open: `data/wheat_GMZA_observed.csv`

**Replace the example values** with YOUR actual field measurements from Gemiza:

```csv
Experiment,Treatment,Date,Variable,Value,SD
GMZA2001,T1,2001-04-15,HWAM,6500,400
GMZA2001,T1,2001-04-15,CWAM,14000,850
...
```

**Column descriptions:**
- **Experiment**: Keep as "GMZA2001"
- **Treatment**: Your treatment codes (T1, T2, Irrigated, Rainfed, N100, N150, etc.)
- **Date**: Observation date in YYYY-MM-DD format
- **Variable**: DSSAT variable code (see table below)
- **Value**: Your measured value
- **SD**: Standard deviation (optional but recommended)

**Variable Codes for Egyptian Wheat:**

| Code  | Description                      | Typical Range | Unit       |
|-------|----------------------------------|---------------|------------|
| HWAM  | Grain yield                      | 4,000-8,000   | kg/ha      |
| CWAM  | Total above-ground biomass       | 10,000-18,000 | kg/ha      |
| LAIX  | Maximum leaf area index          | 4.0-6.5       | m²/m²      |
| GNAM  | Grain nitrogen content           | 100-180       | kg/ha      |
| ADAT  | Anthesis date (days after plant) | 75-95         | days (DAP) |
| MDAT  | Maturity date (days after plant) | 120-140       | days (DAP) |

**Tips for Egyptian wheat data:**
- Egyptian wheat typically has high yields (5,000-7,000 kg/ha)
- Gemiza location has Mediterranean climate
- Wheat season: November planting, April-May harvest
- Include multiple treatments if available (different N rates, irrigation, etc.)

---

### STEP 3: Verify File Paths

Make sure these files exist in your DSSAT directory:

```
C:\Users\DELL\OneDrive\Desktop\originaldssat\
├── GMZA2001.WHX (or GMZA2001.WHX.txt)
├── GMZA2001.WHA (or GMZA2001.WHA.txt)
├── Genotype\
│   ├── WHCER048.CUL
│   └── WHCER048.ECO
```

**Note**: If your files have `.txt` extensions, you may need to:
- Remove the `.txt` extension, OR
- Update the file names in the script (lines 33-36)

---

## 🚀 HOW TO RUN

### Method 1: From R Console

```r
# Set working directory to where script is located
setwd("path/to/your/workspace")

# Run the calibration
source("calibrate_wheat_GMZA2001.R")
main()
```

### Method 2: From Windows Command Line

```cmd
cd C:\path\to\your\workspace
Rscript calibrate_wheat_GMZA2001.R
```

### Method 3: From RStudio

1. Open `calibrate_wheat_GMZA2001.R` in RStudio
2. Click "Source" button, OR
3. Run: `main()`

---

## 📊 WHAT THE SCRIPT DOES

1. **Checks DSSAT installation** and verifies all files exist
2. **Loads your observed data** from `wheat_GMZA_observed.csv`
3. **Runs optimization** to find best-fit genetic coefficients
4. **Generates comprehensive report** with results
5. **Creates comparison plots** (observed vs simulated)
6. **Saves all results** to `wheat_GMZA_calibration_output/`

---

## 📁 OUTPUT FILES

After calibration completes, you'll find:

```
wheat_GMZA_calibration_output/
├── calibrated_parameters_GMZA.csv     ← Optimized genetic coefficients
├── obs_vs_sim_GMZA.csv               ← Model performance comparison
├── calibration_report_GMZA.txt       ← Complete report with instructions
└── plots/
    └── obs_vs_sim_scatter.png        ← Visual comparison plot
```

---

## 🎯 AFTER CALIBRATION

### 1. Review Results

Open: `wheat_GMZA_calibration_output/calibration_report_GMZA.txt`

Check:
- ✅ Convergence status
- ✅ MAPE (Mean Absolute Percent Error) - should be < 20%
- ✅ Individual variable errors

### 2. Update DSSAT Cultivar File

The report shows you **exactly** what values to put in your `.CUL` file:

**Location of file:**
```
C:\Users\DELL\OneDrive\Desktop\originaldssat\Genotype\WHCER048.CUL
```

**What to update:**
Find the line with your cultivar name and update these columns:
- P1V (Vernalization)
- P1D (Photoperiod)
- P5 (Grain filling)
- G1 (Kernel number)
- G2 (Kernel weight)
- G3 (Stem weight)
- PHINT (Phylochron)

The report gives you the exact values formatted for the .CUL file!

### 3. Validate

**IMPORTANT**: Before using for predictions:
- Test on independent data (different year/location)
- Compare with literature values for Egyptian wheat
- Check if parameters are biologically reasonable

---

## ⚙️ CUSTOMIZATION

### Adjust Parameter Ranges

If calibration doesn't converge or gives unrealistic values, edit lines 46-54:

```r
CALIB_PARAMS <- list(
  P1V = c(min = 0, max = 50, init = 15),    # Adjust these ranges
  P1D = c(min = 20, max = 100, init = 60),  # based on your cultivar
  ...
)
```

### Change Optimization Settings

Edit lines 73-76:

```r
MAX_ITERATIONS <- 150           # Increase if not converging
CONVERGENCE_TOLERANCE <- 0.001  # Make smaller for stricter fit
OPTIMIZATION_METHOD <- "L-BFGS-B"  # Or try "Nelder-Mead"
```

### Adjust Variable Weights

To emphasize certain variables (e.g., yield more important than LAI):

Edit lines 63-70:

```r
VARIABLE_WEIGHTS <- list(
  HWAM = 5.0,   # Make yield even more important
  CWAM = 1.5,
  LAIX = 0.5,   # Make LAI less important
  ...
)
```

---

## ❓ TROUBLESHOOTING

### Problem: "DSSAT directory not found"
**Solution**: 
- Check the path on line 26
- Make sure: `C:\Users\DELL\OneDrive\Desktop\originaldssat` exists
- Use forward slashes `/` or double backslashes `\\`

### Problem: "Experiment file not found"
**Solution**:
- Your files might have `.txt` extension
- Check actual filename: `GMZA2001.WHX.txt`
- Update line 33: `EXPERIMENT_FILE <- "GMZA2001.WHX.txt"`

### Problem: "No observed data"
**Solution**:
- Fill in `data/wheat_GMZA_observed.csv` with real measurements
- Make sure values are not zero or empty
- Check date format: YYYY-MM-DD

### Problem: "Calibration not converging"
**Solutions**:
1. Increase `MAX_ITERATIONS` to 200 or 300
2. Widen parameter ranges in `CALIB_PARAMS`
3. Check if observed data is realistic
4. Try different optimization method

### Problem: "Poor fit (high MAPE)"
**Possible causes**:
1. Observed data has errors
2. Parameter ranges too restrictive
3. Wrong cultivar selected
4. Weather data issues
5. Need more observed variables

---

## 📚 REFERENCES

### Egyptian Wheat Cultivars
Common varieties calibrated for Egypt:
- Sakha 93, 94, 95
- Gemiza 9, 10, 11, 12
- Sids 1, 12, 13, 14
- Giza 168, 171
- Misr 1, 2, 3

### CERES-Wheat Parameters
- **P1V**: Vernalization requirement (days at 3°C)
  - Egyptian wheat: Usually 0-20 (spring type)
- **P1D**: Photoperiod sensitivity (%)
  - Egyptian wheat: 40-80
- **P5**: Grain filling (°C·d)
  - Egyptian wheat: 450-650
- **G1**: Kernel number
  - Egyptian wheat: 20-30
- **G2**: Kernel weight (mg)
  - Egyptian wheat: 40-50
- **G3**: Stem weight (g)
  - Egyptian wheat: 1.5-2.5
- **PHINT**: Phylochron (°C·d)
  - Egyptian wheat: 85-105

---

## 📞 SUPPORT

For issues:
1. Check this README first
2. Review the main calibration documentation
3. Check DSSAT documentation: https://dssat.net/
4. Review error messages carefully

---

## ✅ CHECKLIST BEFORE RUNNING

- [ ] Updated `CULTIVAR_NAME` in script (line 40)
- [ ] Filled `data/wheat_GMZA_observed.csv` with real data
- [ ] Verified DSSAT directory path exists
- [ ] Confirmed GMZA2001.WHX file exists
- [ ] Confirmed GMZA2001.WHA file exists
- [ ] Confirmed WHCER048.CUL file exists in Genotype folder
- [ ] Have at least 3-4 observed variables (HWAM, ADAT, MDAT minimum)

---

## 🎉 YOU'RE READY!

Once you've completed the checklist above, simply run:

```r
source("calibrate_wheat_GMZA2001.R")
main()
```

The script will guide you through the entire process!

---

**Version**: 1.0  
**Date**: 2026-01-01  
**Location**: Gemiza, Egypt  
**Crop**: Wheat (CERES-Wheat Model)

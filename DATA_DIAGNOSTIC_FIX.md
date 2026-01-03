# 🔍 DATA COMPARISON DIAGNOSTIC FIX

## Issue Encountered

**Progress:**
```
Step 6: Preparing data for plotting...
  ✓ Data prepared: 0 comparison points  ← Problem!

Step 7: Calculating statistics...
Error in if (nrow(var_data) == 0) next : argument is of length zero
```

## Root Cause

The simulations ran successfully (0 errors), but when trying to merge observed and simulated data for comparison, **no matching data** was found. This could be due to:

1. **Variable name mismatch** between observations and simulations
2. **Situation name mismatch** 
3. **Column naming differences**
4. **Data structure incompatibility**

## Fixes Applied

### Fix 1: Added Detailed Diagnostics

The script now prints diagnostic information during data preparation:

```r
cat("  Observations loaded:", nrow(obs_df), "rows\n")
cat("  Observation columns:", paste(names(obs_df), collapse = ", "), "\n")
cat("  Initial simulations:", nrow(sim_initial_final), "final rows\n")
cat("  Simulation columns:", paste(names(sim_initial_final), collapse = ", "), "...\n")
```

### Fix 2: Per-Variable Diagnostics

For each variable, the script now reports:

```r
cat("  Checking variable availability...\n")
for (var in variables) {
  if (!(var %in% names(obs_df))) {
    cat("    ⚠ Variable", var, "not in observations, skipping\n")
  } else if (nrow(merged) == 0) {
    cat("    ⚠ Variable", var, "has no matching situations, skipping\n")
  } else {
    cat("    ✓ Variable", var, ":", nrow(merged), "comparison points\n")
  }
}
```

### Fix 3: Auto-Generate Debug File

If no comparison data is found, the script now saves a detailed debug file:

```r
# Saved to: Sakha95_CORRECTED_results/debug_info.txt
=== OBSERVATIONS ===
Rows: XXX
Columns: Situation, Date, HWAM, ADAT, ...
Situations: GMZA2001_1, GMZA2001_2, ...

=== SIMULATIONS (Initial) ===
Rows: XXX
Columns: Situation, Date, HWAM, ADAT, ...
Situations: GMZA2001_1, GMZA2001_2, ...
```

### Fix 4: Better Error Handling

```r
# Handle NULL or invalid var_data
if (is.null(var_data) || !is.data.frame(var_data) || nrow(var_data) == 0) next

# Check if stats_table has data before printing
if (nrow(stats_table) > 0) {
  print(stats_table)
} else {
  cat("\n  ⚠ No statistics could be calculated\n\n")
}
```

## What Will Happen Now

### Scenario 1: Data Matches Successfully

```
Step 6: Preparing data for plotting...
  Observations loaded: 185 rows
  Observation columns: Situation, Date, HWAM, ADAT, H#AM, HWUM
  Initial simulations: 50 final rows
  Simulation columns: Situation, Date, HWAM, ADAT, LAIX, ...
  Checking variable availability...
    ✓ Variable HWAM : 51 comparison points
    ✓ Variable ADAT : 49 comparison points
    ✓ Variable H#AM : 7 comparison points
    ✓ Variable HWUM : 30 comparison points
  ✓ Data prepared: 137 comparison points

Step 7: Calculating statistics...
  [Statistics table printed]
  ✓ Statistics calculated
```

### Scenario 2: Data Mismatch (Current Issue)

```
Step 6: Preparing data for plotting...
  Observations loaded: 185 rows
  Observation columns: Situation, HWAM, ADAT, ...
  Initial simulations: 50 final rows
  Simulation columns: Situation, Date, hwam, adat, ...  ← Note case difference!
  Checking variable availability...
    ⚠ Variable HWAM not in simulations, skipping
    ⚠ Variable ADAT not in simulations, skipping
    ⚠ Variable H#AM not in simulations, skipping
    ⚠ Variable HWUM not in simulations, skipping
  ✓ Data prepared: 0 comparison points

╔═══════════════════════════════════════════════════════════════╗
║  WARNING: No comparison data available                      ║
╚═══════════════════════════════════════════════════════════════╝

Possible reasons:
  1. Variable names don't match between obs and sim
  2. Situation names don't match
  3. No overlapping data

Debug information saved to: Sakha95_CORRECTED_results/debug_info.txt
```

## How to Use Debug Info

Once the script runs again, check the console output to see:

1. **What columns are in observations**
2. **What columns are in simulations**
3. **Which variables matched or didn't match**

Common issues:

| Problem | Symptom | Solution |
|---------|---------|----------|
| Case mismatch | `HWAM` vs `hwam` | Add `toupper()` conversion |
| Different names | `HWAM` vs `GrainYield` | Map variable names |
| Missing columns | Variable not in simulation output | Check DSSAT output options |
| Situation mismatch | `GMZA2001_1` vs `GMZA2001-1` | Fix delimiter |

## Next Steps

### Step 1: Run the Fixed Script

```r
setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")
source("visualize_Sakha95_calibration.R")
```

### Step 2: Review Console Output

Look for the new diagnostic messages in Step 6

### Step 3A: If Data Matches ✅

Script will continue automatically and create all plots!

### Step 3B: If Data Still Doesn't Match ⚠️

1. Check the console output for column names
2. Review `debug_info.txt` file
3. **Paste the console output** showing:
   - Observation columns
   - Simulation columns
   - Variable availability messages

I can then create a variable name mapping fix.

## Common DSSAT Variable Names

DSSAT simulations typically output these column names:

| Our Variable | DSSAT Column | Alternative Names |
|--------------|--------------|-------------------|
| HWAM | HWAM, Grain_Yield | GrainYield, GYLD |
| ADAT | ADAT, Anthesis_Date | AnthesisDate, ADATE |
| H#AM | GNUM, Grain_Number | GrainNumber, GRNNO |
| HWUM | GWAM, Grain_Weight | GrainWeight, GWGT |

The fix may require adding a name translation step.

## Status

✅ **Enhanced diagnostics added**
✅ **Debug file generation enabled**  
✅ **Better error handling**
✅ **Ready to identify the data mismatch issue**

---

**Please run the script again and share the console output from Step 6!** 🔍

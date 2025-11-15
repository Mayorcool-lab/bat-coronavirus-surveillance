# Step 9: Selection Analysis Scripts

## Overview

Complete selection analysis pipeline for SARS-CoV-2 RBD evolution.

## Scripts

### Step 9.7: RBD Extraction
- **Script:** `09.7_extract_rbd.sh`
- **Purpose:** Extract RBD region (aa 319-541) from spike alignment
- **Output:** `rbd_aligned_16.faa`

### Step 9.8: Selection Analysis

#### Individual Components:
1. **`09.8.1_prepare_alignment.sh`**
   - Check alignment quality
   - Count variable sites

2. **`09.8.2_analyze_variation.sh`**
   - Calculate Shannon entropy per position
   - Identify variable sites
   - Output: `variation_analysis.json`

3. **`09.8.3_map_mutations.sh`**
   - Map to known variant mutations
   - Validate against Alpha, Beta, Gamma, Delta, Omicron

4. **`09.8.4_visualize.sh`**
   - Create publication-quality figures
   - Output: `selection_analysis_results.png`, `rbd_alignment_heatmap.png`

5. **`09.8.5_generate_report.sh`**
   - Generate comprehensive markdown report
   - Output: `SELECTION_ANALYSIS_REPORT.md`

#### Master Script:
- **`09.8_run_all.sh`**
  - Runs all 5 sub-steps in sequence
  - Complete pipeline execution

## Usage

### Run Individual Steps:
```bash
cd ~/bat_viral_pipeline/scripts/phylogenetics/step9_selection_analysis

# Step 9.7
bash 09.7_extract_rbd.sh

# Step 9.8 (individual)
bash 09.8.1_prepare_alignment.sh
bash 09.8.2_analyze_variation.sh
bash 09.8.3_map_mutations.sh
bash 09.8.4_visualize.sh
bash 09.8.5_generate_report.sh
```

### Run Complete Pipeline:
```bash
# Run all of Step 9.8 at once
bash 09.8_run_all.sh
```

## Outputs

All outputs are created in: `results/phylogenetics/selection_analysis/`

- `rbd_aligned_16.faa` - RBD alignment
- `variation_analysis.json` - Raw variation data
- `selection_analysis_results.png` - Multi-panel visualization
- `selection_analysis_results.pdf` - Vector graphics
- `rbd_alignment_heatmap.png` - Sequence heatmap
- `SELECTION_ANALYSIS_REPORT.md` - Comprehensive report

## Requirements

- Python 3.x
- Biopython
- Matplotlib
- NumPy

## Author

Created: 2024-11-12  
Purpose: Leibniz-IZW PANDASIA Project Application


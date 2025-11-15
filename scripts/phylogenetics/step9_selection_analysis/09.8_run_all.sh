#!/bin/bash

#############################################################################
# Script: 09.8_run_all.sh
# Purpose: Master script to run complete selection analysis pipeline
# Author: Your Name
# Date: 2024-11-12
#
# Description:
#   Runs all Step 9.8 sub-scripts in sequence:
#   - 9.8.1: Prepare alignment
#   - 9.8.2: Analyze variation
#   - 9.8.3: Map mutations
#   - 9.8.4: Create visualizations
#   - 9.8.5: Generate report
#
# Input:
#   - rbd_aligned_16.faa (from Step 9.7)
#
# Output:
#   - All selection analysis results
#
# Usage:
#   bash 09.8_run_all.sh
#############################################################################

set -euo pipefail

echo "=========================================="
echo "STEP 9.8: COMPLETE SELECTION ANALYSIS"
echo "=========================================="
echo ""
echo "This will run all 5 sub-steps:"
echo "  9.8.1: Prepare alignment"
echo "  9.8.2: Analyze variation"
echo "  9.8.3: Map to known mutations"
echo "  9.8.4: Create visualizations"
echo "  9.8.5: Generate report"
echo ""
echo "⏱️  Estimated time: 5-10 minutes"
echo ""

read -p "Press ENTER to start..."
echo ""

# Run each step
bash 09.8.1_prepare_alignment.sh
echo ""

bash 09.8.2_analyze_variation.sh
echo ""

bash 09.8.3_map_mutations.sh
echo ""

bash 09.8.4_visualize.sh
echo ""

bash 09.8.5_generate_report.sh
echo ""

# Final summary
echo "=========================================="
echo "✅ COMPLETE SELECTION ANALYSIS FINISHED!"
echo "=========================================="
echo ""
echo "All outputs created in:"
echo "  results/phylogenetics/selection_analysis/"
echo ""
echo "Key files:"
echo "  ✓ variation_analysis.json"
echo "  ✓ selection_analysis_results.png"
echo "  ✓ rbd_alignment_heatmap.png"
echo "  ✓ SELECTION_ANALYSIS_REPORT.md"
echo ""


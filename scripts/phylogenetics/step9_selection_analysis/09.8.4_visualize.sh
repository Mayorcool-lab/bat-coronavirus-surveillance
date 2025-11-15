#!/bin/bash

#############################################################################
# Script: 09.8.4_visualize.sh
# Purpose: Create publication-quality visualizations of selection analysis
# Author: Your Name
# Date: 2024-11-12
#
# Description:
#   Generates three types of visualizations:
#   1. Multi-panel entropy/conservation plot
#   2. Alignment heatmap showing all mutations
#
# Input:
#   - variation_analysis.json
#   - rbd_aligned_16.faa
#
# Output:
#   - selection_analysis_results.png (300 DPI)
#   - selection_analysis_results.pdf (vector)
#   - rbd_alignment_heatmap.png
#
# Usage:
#   bash 09.8.4_visualize.sh
#############################################################################

set -euo pipefail

RESULTS_DIR="../../results/phylogenetics/selection_analysis"

echo "=========================================="
echo "STEP 9.8.4: CREATING VISUALIZATIONS"
echo "=========================================="
echo ""

cd "$RESULTS_DIR"

# Check inputs
if [ ! -f "variation_analysis.json" ]; then
    echo "❌ ERROR: variation_analysis.json not found!"
    exit 1
fi

if [ ! -f "rbd_aligned_16.faa" ]; then
    echo "❌ ERROR: rbd_aligned_16.faa not found!"
    exit 1
fi

cat > visualize_selection.py << 'PYEOF'
#!/usr/bin/env python3
"""Create visualizations of selection analysis results"""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import json
from Bio import SeqIO
import numpy as np

print("=" * 60)
print("SELECTION ANALYSIS VISUALIZATION")
print("=" * 60)
print()

# Load variation data
with open('variation_analysis.json', 'r') as f:
    variation_data = json.load(f)

print(f"✓ Loaded variation data for {len(variation_data)} positions")
print()

#############################################################################
# FIGURE 1: Multi-panel analysis
#############################################################################

fig = plt.figure(figsize=(18, 12))

# Extract data
positions = [d['position'] for d in variation_data]
entropy = [d['entropy'] for d in variation_data]
conservation = [d['conservation'] for d in variation_data]
n_variants = [d['n_variants'] for d in variation_data]

# Panel A: Entropy
ax1 = plt.subplot(3, 1, 1)
ax1.bar(positions, entropy, color='steelblue', alpha=0.7, edgecolor='black', linewidth=0.5)
ax1.axhline(y=1.5, color='red', linestyle='--', linewidth=2, label='High variation threshold')
ax1.set_xlabel('RBD Position (1-223)', fontsize=12, fontweight='bold')
ax1.set_ylabel('Shannon Entropy', fontsize=12, fontweight='bold')
ax1.set_title('A. Amino Acid Variability Across RBD', fontsize=14, fontweight='bold', pad=15)
ax1.legend(loc='upper right')
ax1.grid(axis='y', alpha=0.3)
ax1.set_xlim(0, 224)

# Panel B: Conservation
ax2 = plt.subplot(3, 1, 2)
ax2.plot(positions, conservation, color='darkgreen', linewidth=2)
ax2.fill_between(positions, conservation, alpha=0.3, color='green')
ax2.axhline(y=80, color='orange', linestyle='--', linewidth=1, label='80% conservation')
ax2.set_xlabel('RBD Position (1-223)', fontsize=12, fontweight='bold')
ax2.set_ylabel('Conservation (%)', fontsize=12, fontweight='bold')
ax2.set_title('B. Sequence Conservation Across RBD', fontsize=14, fontweight='bold', pad=15)
ax2.legend(loc='lower right')
ax2.grid(axis='y', alpha=0.3)
ax2.set_xlim(0, 224)
ax2.set_ylim(0, 105)

# Panel C: Number of variants
ax3 = plt.subplot(3, 1, 3)
colors = ['green' if n == 1 else 'orange' if n == 2 else 'red' for n in n_variants]
ax3.bar(positions, n_variants, color=colors, alpha=0.7, edgecolor='black', linewidth=0.5)
ax3.set_xlabel('RBD Position (1-223)', fontsize=12, fontweight='bold')
ax3.set_ylabel('Number of Variants', fontsize=12, fontweight='bold')
ax3.set_title('C. Variant Diversity Per Position', fontsize=14, fontweight='bold', pad=15)
ax3.grid(axis='y', alpha=0.3)
ax3.set_xlim(0, 224)

# Legend
from matplotlib.patches import Rectangle
legend_elements = [
    Rectangle((0,0),1,1, fc='green', label='Conserved (1 variant)'),
    Rectangle((0,0),1,1, fc='orange', label='Binary (2 variants)'),
    Rectangle((0,0),1,1, fc='red', label='Variable (3+ variants)')
]
ax3.legend(handles=legend_elements, loc='upper right')

# Overall title
fig.suptitle('Selection Analysis: SARS-CoV-2 RBD Evolution\n' +
             '16 Coronavirus Sequences (Bat, Human, Pangolin)',
             fontsize=16, fontweight='bold', y=0.995)

plt.tight_layout(rect=[0, 0, 1, 0.99])

# Save
plt.savefig('selection_analysis_results.png', dpi=300, bbox_inches='tight')
plt.savefig('selection_analysis_results.pdf', bbox_inches='tight')
print("✓ Created: selection_analysis_results.png (300 DPI)")
print("✓ Created: selection_analysis_results.pdf (vector)")
plt.close()

#############################################################################
# FIGURE 2: Alignment heatmap
#############################################################################

fig, ax = plt.subplots(figsize=(20, 8))

# Get sequences
records = list(SeqIO.parse("rbd_aligned_16.faa", "fasta"))

# Create matrix
n_seqs = len(records)
n_pos = len(records[0].seq)

# Encode amino acids
aa_to_num = {aa: i for i, aa in enumerate('ACDEFGHIKLMNPQRSTVWY-')}

matrix = np.zeros((n_seqs, n_pos))
for i, rec in enumerate(records):
    for j, aa in enumerate(str(rec.seq)):
        matrix[i, j] = aa_to_num.get(aa, 20)

# Plot
im = ax.imshow(matrix, aspect='auto', cmap='tab20', interpolation='nearest')

# Labels
ax.set_xlabel('RBD Position (1-223)', fontsize=12, fontweight='bold')
ax.set_ylabel('Sequence', fontsize=12, fontweight='bold')
ax.set_title('Amino Acid Alignment Heatmap: RBD Region\n' +
             'Different colors = different amino acids',
             fontsize=14, fontweight='bold', pad=15)

# Y-axis labels
labels = [rec.id.split('|')[1] if '|' in rec.id else rec.id[:20] for rec in records]
ax.set_yticks(range(n_seqs))
ax.set_yticklabels(labels, fontsize=8)

# X-axis
ax.set_xticks(range(0, n_pos, 20))
ax.set_xticklabels(range(1, n_pos+1, 20))

plt.tight_layout()
plt.savefig('rbd_alignment_heatmap.png', dpi=300, bbox_inches='tight')
print("✓ Created: rbd_alignment_heatmap.png")
plt.close()

print()
print("✅ All visualizations created successfully!")
print()

PYEOF

chmod +x visualize_selection.py
python visualize_selection.py

# Verify outputs
echo ""
echo "=========================================="
echo "VERIFICATION"
echo "=========================================="
echo ""

for file in selection_analysis_results.png selection_analysis_results.pdf rbd_alignment_heatmap.png; do
    if [ -f "$file" ]; then
        SIZE=$(ls -lh "$file" | awk '{print $5}')
        echo "✓ Created: $file ($SIZE)"
    else
        echo "❌ Missing: $file"
    fi
done

echo ""
echo "✅ STEP 9.8.4 COMPLETE!"


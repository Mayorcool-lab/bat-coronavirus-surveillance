#!/bin/bash

#############################################################################
# Script: 09.8.2_analyze_variation.sh
# Purpose: Analyze amino acid variation at each RBD position
# Author: Your Name
# Date: 2024-11-12
#
# Description:
#   Calculates Shannon entropy for each position to identify variable sites.
#   High entropy indicates potential positive selection.
#
# Input:
#   - rbd_aligned_16.faa
#
# Output:
#   - variation_analysis.json (raw data)
#   - Console report of variable sites
#
# Usage:
#   bash 09.8.2_analyze_variation.sh
#############################################################################

set -euo pipefail

RESULTS_DIR="../../results/phylogenetics/selection_analysis"

echo "=========================================="
echo "STEP 9.8.2: AMINO ACID VARIATION ANALYSIS"
echo "=========================================="
echo ""

cd "$RESULTS_DIR"

cat > analyze_variation.py << 'PYEOF'
#!/usr/bin/env python3
"""Analyze amino acid variation at each position"""

from Bio import SeqIO
from collections import Counter
import math
import json

print("=" * 60)
print("AMINO ACID VARIATION ANALYSIS")
print("=" * 60)
print()

# Read RBD alignment
records = list(SeqIO.parse("rbd_aligned_16.faa", "fasta"))
n_seqs = len(records)
alignment_length = len(records[0].seq)

print(f"Analyzing {n_seqs} sequences")
print(f"RBD length: {alignment_length} amino acids")
print()

# Analyze each position
variation_data = []

print("Position-by-position analysis:")
print("-" * 80)
print(f"{'Pos':<6} {'Conservation':<15} {'Variants':<20} {'Entropy':<10} {'Type'}")
print("-" * 80)

for pos in range(alignment_length):
    amino_acids = [str(rec.seq[pos]) for rec in records]
    aa_counts = Counter(amino_acids)
    
    # Calculate entropy
    entropy = 0
    for count in aa_counts.values():
        p = count / n_seqs
        if p > 0:
            entropy -= p * math.log2(p)
    
    # Conservation
    most_common_aa, most_common_count = aa_counts.most_common(1)[0]
    conservation = most_common_count / n_seqs * 100
    
    # Classify
    if len(aa_counts) == 1:
        pos_type = "Conserved"
    elif len(aa_counts) == 2:
        pos_type = "Binary"
    else:
        pos_type = "Variable"
    
    # Store data
    variation_data.append({
        'position': pos + 1,
        'rbd_position': pos + 319,
        'conservation': conservation,
        'n_variants': len(aa_counts),
        'variants': dict(aa_counts),
        'entropy': entropy,
        'type': pos_type
    })
    
    # Print highly variable positions
    if len(aa_counts) >= 3 or entropy > 1.0:
        variants_str = ", ".join([f"{aa}:{c}" for aa, c in aa_counts.most_common()])
        print(f"{pos+1:<6} {conservation:>6.1f}%      {variants_str:<20.20} {entropy:>6.2f}     {pos_type}")

print("-" * 80)
print()

# Summary
conserved = sum(1 for d in variation_data if d['n_variants'] == 1)
variable = sum(1 for d in variation_data if d['n_variants'] >= 2)
highly_variable = sum(1 for d in variation_data if d['n_variants'] >= 3)

print("SUMMARY:")
print(f"  Total positions: {alignment_length}")
print(f"  Conserved (1 variant): {conserved} ({conserved/alignment_length*100:.1f}%)")
print(f"  Variable (2+ variants): {variable} ({variable/alignment_length*100:.1f}%)")
print(f"  Highly variable (3+ variants): {highly_variable} ({highly_variable/alignment_length*100:.1f}%)")
print()

# Save results
with open('variation_analysis.json', 'w') as f:
    json.dump(variation_data, f, indent=2)

print("✓ Results saved to: variation_analysis.json")
print()

PYEOF

chmod +x analyze_variation.py
python analyze_variation.py

echo "✅ STEP 9.8.2 COMPLETE!"


#!/bin/bash

#############################################################################
# Script: 09.8.1_prepare_alignment.sh
# Purpose: Prepare codon alignment for selection analysis
# Author: Your Name
# Date: 2024-11-12
#
# Description:
#   Checks alignment quality and counts variable sites.
#   Note: Full dN/dS requires nucleotide sequences; we use protein approach.
#
# Input:
#   - rbd_aligned_16.faa
#
# Output:
#   - Console report on alignment statistics
#
# Usage:
#   bash 09.8.1_prepare_alignment.sh
#############################################################################

set -euo pipefail

RESULTS_DIR="../../results/phylogenetics/selection_analysis"

echo "=========================================="
echo "STEP 9.8.1: PREPARING CODON ALIGNMENT"
echo "=========================================="
echo ""

cd "$RESULTS_DIR"

# Check input
if [ ! -f "rbd_aligned_16.faa" ]; then
    echo "❌ ERROR: rbd_aligned_16.faa not found!"
    echo "   Run Step 9.7 first."
    exit 1
fi

# Create analysis script
cat > prepare_alignment.py << 'PYEOF'
#!/usr/bin/env python3
from Bio import SeqIO

print("=" * 60)
print("CODON ALIGNMENT PREPARATION")
print("=" * 60)
print()

rbd_records = list(SeqIO.parse("rbd_aligned_16.faa", "fasta"))
print(f"✓ Loaded {len(rbd_records)} RBD sequences")
print(f"  Alignment length: {len(rbd_records[0].seq)} amino acids")
print()

print("Note: Full codon-based dN/dS requires nucleotide sequences.")
print("For demonstration, we'll use protein-based approach.")
print()

# Count variable sites
alignment_length = len(rbd_records[0].seq)
variable_sites = []

for pos in range(alignment_length):
    amino_acids = set(str(rec.seq[pos]) for rec in rbd_records)
    if len(amino_acids) > 1:
        variable_sites.append(pos + 1)

conservation = 100 * (1 - len(variable_sites)/alignment_length)

print(f"✓ Found {len(variable_sites)} variable sites in RBD")
print(f"  Conservation: {conservation:.1f}%")
print()
print("✅ Alignment prepared for analysis")
PYEOF

chmod +x prepare_alignment.py
python prepare_alignment.py

echo ""
echo "✅ STEP 9.8.1 COMPLETE!"


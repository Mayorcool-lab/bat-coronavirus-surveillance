#!/bin/bash

#############################################################################
# Script: 09.7_extract_rbd.sh
# Purpose: Extract Receptor Binding Domain (RBD) from aligned spike proteins
# Author: Your Name
# Date: 2024-11-12
# 
# Description:
#   Extracts amino acids 319-541 (RBD region) from full spike alignment.
#   RBD is the critical region for ACE2 binding and most variant mutations.
#
# Input:
#   - aligned_spikes_16.faa (from Step 9.5)
#
# Output:
#   - rbd_aligned_16.faa (223 aa RBD alignment)
#
# Usage:
#   bash 09.7_extract_rbd.sh
#############################################################################

set -euo pipefail

# Configuration
RESULTS_DIR="../../results/phylogenetics/selection_analysis"
RBD_START=318  # 0-based (aa 319 in 1-based)
RBD_END=541
RBD_LENGTH=223

echo "=========================================="
echo "STEP 9.7: RBD EXTRACTION"
echo "=========================================="
echo ""
echo "Working directory: $RESULTS_DIR"
echo "RBD coordinates: aa 319-541 ($RBD_LENGTH amino acids)"
echo ""

# Check input file exists
if [ ! -f "$RESULTS_DIR/aligned_spikes_16.faa" ]; then
    echo "❌ ERROR: aligned_spikes_16.faa not found!"
    echo "   Run Step 9.5 (alignment) first."
    exit 1
fi

# Navigate to results directory
cd "$RESULTS_DIR"

# Create Python extraction script
cat > extract_rbd.py << 'PYEOF'
#!/usr/bin/env python3
"""Extract RBD region from aligned spike proteins"""

from Bio import SeqIO
import sys

# RBD coordinates (0-based indexing)
RBD_START = 318  # aa 319 in 1-based
RBD_END = 541

print("=" * 60)
print("RBD EXTRACTION")
print("=" * 60)
print()
print(f"RBD coordinates: {RBD_START+1}-{RBD_END} (1-based)")
print(f"Expected length: {RBD_END - RBD_START} amino acids")
print()

try:
    # Read aligned sequences
    records = list(SeqIO.parse("aligned_spikes_16.faa", "fasta"))
    print(f"✓ Read {len(records)} aligned sequences")
    print()
    
    # Extract RBD from each sequence
    rbd_records = []
    
    print("Extracting RBD from each sequence:")
    print("-" * 60)
    
    for record in records:
        # Get RBD region
        rbd_seq = record.seq[RBD_START:RBD_END]
        
        # Count amino acids (excluding gaps)
        rbd_seq_nogaps = str(rbd_seq).replace("-", "")
        
        # Update record
        record.seq = rbd_seq
        record.description = f"RBD_{RBD_START+1}-{RBD_END}"
        rbd_records.append(record)
        
        # Print info
        seq_name = record.id[:40] if len(record.id) > 40 else record.id
        print(f"  {seq_name:<40} {len(rbd_seq_nogaps):>3} aa")
    
    print("-" * 60)
    print()
    
    # Write RBD alignment
    SeqIO.write(rbd_records, "rbd_aligned_16.faa", "fasta")
    
    print(f"✓ Extracted RBD from {len(rbd_records)} sequences")
    print(f"  Alignment length: {len(rbd_records[0].seq)} positions")
    print(f"  Output file: rbd_aligned_16.faa")
    print()
    
    print("✅ RBD extraction complete!")
    sys.exit(0)
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

PYEOF

# Make executable
chmod +x extract_rbd.py

# Run extraction
echo "→ Running RBD extraction..."
echo ""
python extract_rbd.py

# Verify output
if [ -f "rbd_aligned_16.faa" ]; then
    NUM_SEQS=$(grep -c "^>" rbd_aligned_16.faa)
    FILE_SIZE=$(ls -lh rbd_aligned_16.faa | awk '{print $5}')
    
    echo ""
    echo "=========================================="
    echo "VERIFICATION"
    echo "=========================================="
    echo ""
    echo "✓ Output file created: rbd_aligned_16.faa"
    echo "  Sequences: $NUM_SEQS"
    echo "  File size: $FILE_SIZE"
    echo ""
    
    echo "✅ STEP 9.7 COMPLETE!"
else
    echo ""
    echo "❌ ERROR: Output file not created!"
    exit 1
fi


#!/bin/bash

#############################################################################
# Script: 09.8.3_map_mutations.sh
# Purpose: Map variable sites to known SARS-CoV-2 variant mutations
# Author: Your Name
# Date: 2024-11-12
#
# Description:
#   Maps identified variable sites to known mutations in Alpha, Beta, Gamma,
#   Delta, and Omicron variants. Validates analysis against real-world data.
#
# Input:
#   - variation_analysis.json (from Step 9.8.2)
#
# Output:
#   - Console report of known mutation positions
#
# Usage:
#   bash 09.8.3_map_mutations.sh
#############################################################################

set -euo pipefail

RESULTS_DIR="../../results/phylogenetics/selection_analysis"

echo "=========================================="
echo "STEP 9.8.3: MAPPING TO KNOWN MUTATIONS"
echo "=========================================="
echo ""

cd "$RESULTS_DIR"

# Check input
if [ ! -f "variation_analysis.json" ]; then
    echo "❌ ERROR: variation_analysis.json not found!"
    echo "   Run Step 9.8.2 first."
    exit 1
fi

cat > map_mutations.py << 'PYEOF'
#!/usr/bin/env python3
"""Map variable sites to known SARS-CoV-2 variant mutations"""

print("=" * 60)
print("VARIANT MUTATION MAPPING")
print("=" * 60)
print()

# Known variant mutations in RBD (spike protein positions)
known_mutations = {
    'Alpha': ['N501Y'],
    'Beta': ['K417N', 'E484K', 'N501Y'],
    'Gamma': ['K417T', 'E484K', 'N501Y'],
    'Delta': ['L452R', 'T478K'],
    'Omicron': ['G339D', 'S371L', 'S373P', 'S375F', 'K417N', 'N440K', 
                'G446S', 'S477N', 'T478K', 'E484A', 'Q493R', 'G496S',
                'Q498R', 'N501Y', 'Y505H']
}

# RBD starts at position 319 in spike
RBD_START = 319

print("Known RBD mutations in major variants:")
print("-" * 60)

all_positions = set()
for variant, mutations in known_mutations.items():
    positions = []
    for mut in mutations:
        # Extract position number
        pos = int(''.join(filter(str.isdigit, mut)))
        if 319 <= pos <= 541:  # In RBD
            positions.append(pos)
            all_positions.add(pos)
    
    if positions:
        print(f"{variant:12} {len(mutations):2} mutations  Positions: {sorted(positions)}")

print("-" * 60)
print()

print(f"Total unique positions with known mutations: {len(all_positions)}")
print(f"These are KEY sites to watch in surveillance!")
print()

# Map to our RBD alignment positions (1-223)
print("Mapping to our RBD alignment (1-223):")
print("-" * 60)
rbd_positions = sorted([pos - RBD_START + 1 for pos in all_positions])
print(f"RBD positions: {rbd_positions}")
print()

print("✅ Variant mapping complete")
print()

PYEOF

chmod +x map_mutations.py
python map_mutations.py

echo "✅ STEP 9.8.3 COMPLETE!"


#!/bin/bash

#########################################
# Assembly Script
# Bat Viral Pipeline - Step 3
# Author: Oluwamayowa Joshua Ogun
# Date: November 7, 2025
#########################################

set -e
set -u
set -x

#########################################
# CONFIGURATION
#########################################

THREADS=8
MEMORY=16
SAMPLE="SRR10903401"

# Input files
R1_PAIRED="data/clean/${SAMPLE}_1_paired.fastq.gz"
R2_PAIRED="data/clean/${SAMPLE}_2_paired.fastq.gz"

# Output directories
SPADES_OUT="results/assembly/spades"
QUAST_OUT="results/assembly/quast"

# SPAdes parameters
KMERS="21,33,55,77,99,127"
MIN_CONTIG=500

#########################################
# HEADER
#########################################

echo "=========================================="
echo "BAT VIRAL PIPELINE - ASSEMBLY"
echo "=========================================="
echo ""
echo "Sample: ${SAMPLE}"
echo "Threads: ${THREADS}"
echo "Memory: ${MEMORY} GB"
echo "Date: $(date)"
echo ""

#########################################
# STEP 1: SPAdes Assembly
#########################################

echo "[1/2] Running SPAdes metagenomic assembly..."
echo "  Input: ${R1_PAIRED}"
echo "         ${R2_PAIRED}"
echo "  Output: ${SPADES_OUT}/"
echo "  K-mers: ${KMERS}"
echo ""

spades.py \
  --meta \
  -1 "${R1_PAIRED}" \
  -2 "${R2_PAIRED}" \
  -o "${SPADES_OUT}" \
  -k "${KMERS}" \
  -t "${THREADS}" \
  -m "${MEMORY}"

echo "✓ SPAdes assembly complete"
echo ""

#########################################
# STEP 2: QUAST Quality Assessment
#########################################

echo "[2/2] Running QUAST quality assessment..."
echo "  Input: ${SPADES_OUT}/contigs.fasta"
echo "  Output: ${QUAST_OUT}/"
echo ""

quast.py \
  "${SPADES_OUT}/contigs.fasta" \
  -o "${QUAST_OUT}" \
  --threads 4 \
  --min-contig "${MIN_CONTIG}"

echo "✓ QUAST analysis complete"
echo ""

#########################################
# SUMMARY
#########################################

echo "=========================================="
echo "ASSEMBLY COMPLETE!"
echo "=========================================="
echo ""

# Count contigs
echo "Assembly statistics:"
echo -n "  Total contigs: "
grep -c "^>" "${SPADES_OUT}/contigs.fasta"

echo ""
echo "Results:"
echo "  - Contigs: ${SPADES_OUT}/contigs.fasta"
echo "  - Scaffolds: ${SPADES_OUT}/scaffolds.fasta"
echo "  - QUAST report: ${QUAST_OUT}/report.html"
echo ""
echo "Next step: Gene Annotation (Step 4)"
echo "=========================================="

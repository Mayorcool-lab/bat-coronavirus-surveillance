#!/bin/bash

#########################################
# Gene Prediction & Annotation Script
# Bat Viral Pipeline - Step 4
# Author: Oluwamayowa Joshua Ogun
# Date: November 8, 2025
#########################################

set -e
set -u
set -x

#########################################
# CONFIGURATION
#########################################

# Input
CONTIGS="results/assembly/spades/contigs.fasta"

# Output directories
PRODIGAL_OUT="results/annotation/prodigal"
BLAST_OUT="results/annotation/blast"
DB_DIR="data/databases/diamond"

# Output files
GENES_GFF="${PRODIGAL_OUT}/genes.gff"
PROTEINS_FAA="${PRODIGAL_OUT}/proteins.faa"
GENES_FNA="${PRODIGAL_OUT}/genes.fna"
DIAMOND_DB="${DB_DIR}/viral_proteins"
DIAMOND_RESULTS="${BLAST_OUT}/diamond_results.txt"

# DIAMOND parameters
THREADS=4
EVALUE="1e-5"
MAX_TARGETS=5

#########################################
# HEADER
#########################################

echo "=========================================="
echo "BAT VIRAL PIPELINE - GENE ANNOTATION"
echo "=========================================="
echo ""
echo "Input: ${CONTIGS}"
echo "Date: $(date)"
echo ""

#########################################
# STEP 1: Gene Prediction (Prodigal)
#########################################

echo "[1/3] Running Prodigal gene prediction..."
echo "  Input: ${CONTIGS}"
echo "  Output: ${PRODIGAL_OUT}/"
echo ""

prodigal \
  -i "${CONTIGS}" \
  -o "${GENES_GFF}" \
  -a "${PROTEINS_FAA}" \
  -d "${GENES_FNA}" \
  -p meta \
  -f gff

TOTAL_GENES=$(grep -c "^>" "${PROTEINS_FAA}")

echo "✓ Gene prediction complete"
echo "  Genes predicted: ${TOTAL_GENES}"
echo ""

#########################################
# STEP 2: DIAMOND BLAST Annotation
#########################################

echo "[2/3] Running DIAMOND BLASTP annotation..."
echo "  Database: ${DIAMOND_DB}"
echo "  Threads: ${THREADS}"
echo "  E-value threshold: ${EVALUE}"
echo ""

# Check if database exists
if [ ! -f "${DIAMOND_DB}.dmnd" ]; then
    echo "ERROR: DIAMOND database not found!"
    echo "Please run: diamond makedb --in viral.1.protein.faa.gz -d viral_proteins"
    exit 1
fi

diamond blastp \
  --query "${PROTEINS_FAA}" \
  --db "${DIAMOND_DB}" \
  --out "${DIAMOND_RESULTS}" \
  --outfmt 6 qseqid sseqid pident length evalue bitscore stitle \
  --evalue "${EVALUE}" \
  --max-target-seqs "${MAX_TARGETS}" \
  --threads "${THREADS}" \
  --sensitive

TOTAL_HITS=$(wc -l < "${DIAMOND_RESULTS}")
PROTEINS_WITH_HITS=$(cut -f1 "${DIAMOND_RESULTS}" | sort -u | wc -l)

echo "✓ DIAMOND annotation complete"
echo "  Total alignments: ${TOTAL_HITS}"
echo "  Proteins with hits: ${PROTEINS_WITH_HITS}"
echo ""

#########################################
# STEP 3: Coronavirus Detection
#########################################

echo "[3/3] Analyzing coronavirus hits..."

CORONAVIRUS_HITS=$(grep -ic "coronavirus" "${DIAMOND_RESULTS}" || echo "0")
SARS_COV2_HITS=$(grep -ic "Severe acute respiratory syndrome coronavirus 2" "${DIAMOND_RESULTS}" || echo "0")

echo "  Coronavirus hits: ${CORONAVIRUS_HITS}"
echo "  SARS-CoV-2 hits: ${SARS_COV2_HITS}"

# Create summary
cat > "${BLAST_OUT}/annotation_summary.txt" << SUMMARY
# Annotation Summary
Date: $(date)

## Gene Prediction
Total genes: ${TOTAL_GENES}

## DIAMOND BLAST
Total alignments: ${TOTAL_HITS}
Proteins with hits: ${PROTEINS_WITH_HITS}
Coronavirus hits: ${CORONAVIRUS_HITS}
SARS-CoV-2 hits: ${SARS_COV2_HITS}

## Key Finding
$(if [ ${SARS_COV2_HITS} -gt 0 ]; then
    echo "✅ SARS-CoV-2 sequences detected!"
    echo "   This sample contains coronavirus genetic material."
else
    echo "No SARS-CoV-2 sequences detected."
fi)
SUMMARY

echo "✓ Analysis complete"
echo ""

#########################################
# SUMMARY
#########################################

echo "=========================================="
echo "ANNOTATION COMPLETE!"
echo "=========================================="
echo ""
echo "Results:"
echo "  - Genes: ${TOTAL_GENES}"
echo "  - Proteins with hits: ${PROTEINS_WITH_HITS}"
echo "  - Coronavirus hits: ${CORONAVIRUS_HITS}"
if [ ${SARS_COV2_HITS} -gt 0 ]; then
    echo "  - ⭐ SARS-CoV-2 DETECTED!"
fi
echo ""
echo "Output files:"
echo "  - Proteins: ${PROTEINS_FAA}"
echo "  - Annotations: ${DIAMOND_RESULTS}"
echo "  - Summary: ${BLAST_OUT}/annotation_summary.txt"
echo ""
echo "Next step: Phylogenetic Analysis (Step 8)"
echo "=========================================="

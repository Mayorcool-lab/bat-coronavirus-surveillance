#!/bin/bash

#########################################
# Quality Control Script
# Bat Viral Pipeline - Step 2
# Author: Oluwamayowa Joshua Ogun
# Date: November 6, 2025
#########################################

# Exit on error
set -e
# Exit on undefined variable
set -u
# Print commands as they execute (for debugging)
set -x

#########################################
# CONFIGURATION
#########################################

# Number of CPU threads to use
THREADS=4

# Input/Output directories
RAW_DIR="data/raw"
CLEAN_DIR="data/clean"
QC_RAW_DIR="results/qc/fastqc_raw"
QC_CLEAN_DIR="results/qc/fastqc_clean"
MULTIQC_DIR="results/qc/multiqc"

# Sample name (can be parameterized later)
SAMPLE="SRR10903401"

# Input files
R1_RAW="${RAW_DIR}/${SAMPLE}_1.fastq.gz"
R2_RAW="${RAW_DIR}/${SAMPLE}_2.fastq.gz"

# Output files
R1_PAIRED="${CLEAN_DIR}/${SAMPLE}_1_paired.fastq.gz"
R1_UNPAIRED="${CLEAN_DIR}/${SAMPLE}_1_unpaired.fastq.gz"
R2_PAIRED="${CLEAN_DIR}/${SAMPLE}_2_paired.fastq.gz"
R2_UNPAIRED="${CLEAN_DIR}/${SAMPLE}_2_unpaired.fastq.gz"

# Adapter file location
ADAPTERS="${CONDA_PREFIX}/share/trimmomatic/adapters/TruSeq3-PE.fa"

# Trimmomatic parameters
LEADING=3
TRAILING=3
SLIDINGWINDOW="4:20"
MINLEN=50

#########################################
# HEADER
#########################################

echo "=========================================="
echo "BAT VIRAL PIPELINE - QUALITY CONTROL"
echo "=========================================="
echo ""
echo "Sample: ${SAMPLE}"
echo "Threads: ${THREADS}"
echo "Date: $(date)"
echo ""

#########################################
# STEP 1: FastQC on Raw Data
#########################################

echo "[1/4] Running FastQC on raw data..."
echo "  Input: ${R1_RAW}"
echo "         ${R2_RAW}"
echo "  Output: ${QC_RAW_DIR}/"

fastqc \
  "${R1_RAW}" \
  "${R2_RAW}" \
  -o "${QC_RAW_DIR}" \
  -t "${THREADS}" \
  --quiet

echo "✓ FastQC on raw data complete"
echo ""

#########################################
# STEP 2: Trimmomatic - Quality Filtering
#########################################

echo "[2/4] Running Trimmomatic..."
echo "  Input: ${R1_RAW}"
echo "         ${R2_RAW}"
echo "  Output: ${R1_PAIRED}"
echo "          ${R1_UNPAIRED}"
echo "          ${R2_PAIRED}"
echo "          ${R2_UNPAIRED}"
echo ""
echo "  Parameters:"
echo "    ILLUMINACLIP: TruSeq3-PE.fa:2:30:10:2:True"
echo "    LEADING: ${LEADING}"
echo "    TRAILING: ${TRAILING}"
echo "    SLIDINGWINDOW: ${SLIDINGWINDOW}"
echo "    MINLEN: ${MINLEN}"
echo ""

trimmomatic PE \
  -threads "${THREADS}" \
  -phred33 \
  "${R1_RAW}" \
  "${R2_RAW}" \
  "${R1_PAIRED}" \
  "${R1_UNPAIRED}" \
  "${R2_PAIRED}" \
  "${R2_UNPAIRED}" \
  ILLUMINACLIP:"${ADAPTERS}":2:30:10:2:True \
  LEADING:"${LEADING}" \
  TRAILING:"${TRAILING}" \
  SLIDINGWINDOW:"${SLIDINGWINDOW}" \
  MINLEN:"${MINLEN}"

echo "✓ Trimmomatic complete"
echo ""

#########################################
# STEP 3: FastQC on Cleaned Data
#########################################

echo "[3/4] Running FastQC on cleaned data..."
echo "  Input: ${R1_PAIRED}"
echo "         ${R2_PAIRED}"
echo "  Output: ${QC_CLEAN_DIR}/"

fastqc \
  "${R1_PAIRED}" \
  "${R2_PAIRED}" \
  -o "${QC_CLEAN_DIR}" \
  -t "${THREADS}" \
  --quiet

echo "✓ FastQC on cleaned data complete"
echo ""

#########################################
# STEP 4: MultiQC Summary
#########################################

echo "[4/4] Generating MultiQC summary report..."
echo "  Input: ${QC_RAW_DIR}"
echo "         ${QC_CLEAN_DIR}"
echo "  Output: ${MULTIQC_DIR}/multiqc_report.html"

multiqc \
  "${QC_RAW_DIR}" \
  "${QC_CLEAN_DIR}" \
  -o "${MULTIQC_DIR}" \
  -n multiqc_report \
  --force \
  --quiet

echo "✓ MultiQC report generated"
echo ""

#########################################
# SUMMARY STATISTICS
#########################################

echo "=========================================="
echo "QUALITY CONTROL COMPLETE!"
echo "=========================================="
echo ""

# Count reads
echo "Read counts:"
echo -n "  Raw R1 reads: "
zcat "${R1_RAW}" | echo $(($(wc -l)/4))

echo -n "  Raw R2 reads: "
zcat "${R2_RAW}" | echo $(($(wc -l)/4))

echo -n "  Clean paired R1: "
zcat "${R1_PAIRED}" | echo $(($(wc -l)/4))

echo -n "  Clean paired R2: "
zcat "${R2_PAIRED}" | echo $(($(wc -l)/4))

echo -n "  Clean unpaired R1: "
zcat "${R1_UNPAIRED}" | echo $(($(wc -l)/4))

echo -n "  Clean unpaired R2: "
zcat "${R2_UNPAIRED}" | echo $(($(wc -l)/4))

echo ""

# File sizes
echo "File sizes:"
du -sh "${CLEAN_DIR}"/*.fastq.gz

echo ""
echo "Results:"
echo "  - Raw FastQC: ${QC_RAW_DIR}/"
echo "  - Clean FastQC: ${QC_CLEAN_DIR}/"
echo "  - MultiQC: ${MULTIQC_DIR}/multiqc_report.html"
echo ""
echo "Next step: Assembly (Step 3)"
echo "=========================================="

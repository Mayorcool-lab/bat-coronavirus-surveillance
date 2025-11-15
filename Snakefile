"""
Bat Coronavirus Surveillance Pipeline
Snakemake workflow for viral genome assembly and evolutionary analysis

Author: Dr. Oluwamayowa Joshua Ogun
Date: November 2025
"""

# Configuration
configfile: "config/config.yaml"

# Sample information
SAMPLE = config["sample_id"]
THREADS = config["threads"]

# Define all final outputs
rule all:
    input:
        # Quality control
        "results/qc/multiqc_report.html",
        
        # Assembly
        "results/assembly/contigs.fasta",
        "results/assembly/assembly_stats.txt",
        
        # Annotation
        "results/annotation/proteins.faa",
        "results/annotation/spike_blast_results.txt",
        
        # Phylogenetics
        "results/phylogenetics/selection_analysis/phylogenetic_tree_PROFESSIONAL.png",
        "results/phylogenetics/selection_analysis/selection_analysis_results.png",
        "results/phylogenetics/selection_analysis/rbd_alignment_heatmap.png",
        "results/phylogenetics/selection_analysis/SELECTION_ANALYSIS_REPORT.md"

# ============================================================================
# STEP 1: Download data from SRA
# ============================================================================
rule download_data:
    output:
        r1 = "data/raw/{sample}_1.fastq.gz",
        r2 = "data/raw/{sample}_2.fastq.gz"
    params:
        sample = SAMPLE
    log:
        "logs/download_{sample}.log"
    threads: 1
    shell:
        """
        echo "Downloading {params.sample} from NCBI SRA..." > {log}
        fastq-dump --split-files --gzip {params.sample} \
            --outdir data/raw/ 2>> {log}
        echo "Download complete!" >> {log}
        """

# ============================================================================
# STEP 2: Quality control with FastQC
# ============================================================================
rule fastqc:
    input:
        r1 = "data/raw/{sample}_1.fastq.gz",
        r2 = "data/raw/{sample}_2.fastq.gz"
    output:
        html1 = "results/qc/{sample}_1_fastqc.html",
        html2 = "results/qc/{sample}_2_fastqc.html"
    log:
        "logs/fastqc_{sample}.log"
    threads: 2
    shell:
        """
        echo "Running FastQC..." > {log}
        fastqc {input.r1} {input.r2} \
            --outdir results/qc/ \
            --threads {threads} 2>> {log}
        echo "FastQC complete!" >> {log}
        """

# ============================================================================
# STEP 3: Aggregate QC reports with MultiQC
# ============================================================================
rule multiqc:
    input:
        "results/qc/{sample}_1_fastqc.html",
        "results/qc/{sample}_2_fastqc.html"
    output:
        "results/qc/multiqc_report.html"
    log:
        "logs/multiqc.log"
    shell:
        """
        echo "Aggregating QC reports..." > {log}
        multiqc results/qc/ \
            --outdir results/qc/ \
            --force 2>> {log}
        echo "MultiQC complete!" >> {log}
        """

# ============================================================================
# STEP 4: Trim reads with Trimmomatic
# ============================================================================
rule trim_reads:
    input:
        r1 = "data/raw/{sample}_1.fastq.gz",
        r2 = "data/raw/{sample}_2.fastq.gz"
    output:
        r1_paired = "data/clean/{sample}_1_paired.fastq.gz",
        r1_unpaired = "data/clean/{sample}_1_unpaired.fastq.gz",
        r2_paired = "data/clean/{sample}_2_paired.fastq.gz",
        r2_unpaired = "data/clean/{sample}_2_unpaired.fastq.gz"
    log:
        "logs/trimmomatic_{sample}.log"
    threads: THREADS
    params:
        adapters = config["adapters"]
    shell:
        """
        echo "Trimming reads..." > {log}
        trimmomatic PE -threads {threads} \
            {input.r1} {input.r2} \
            {output.r1_paired} {output.r1_unpaired} \
            {output.r2_paired} {output.r2_unpaired} \
            ILLUMINACLIP:{params.adapters}:2:30:10 \
            LEADING:3 TRAILING:3 \
            SLIDINGWINDOW:4:15 MINLEN:36 2>> {log}
        echo "Trimming complete!" >> {log}
        """

# ============================================================================
# STEP 5: Genome assembly with SPAdes
# ============================================================================
rule assemble_genome:
    input:
        r1 = "data/clean/{sample}_1_paired.fastq.gz",
        r2 = "data/clean/{sample}_2_paired.fastq.gz"
    output:
        contigs = "results/assembly/contigs.fasta",
        scaffolds = "results/assembly/scaffolds.fasta"
    log:
        "logs/spades_{sample}.log"
    threads: THREADS
    params:
        outdir = "results/assembly"
    shell:
        """
        echo "Assembling genome with SPAdes..." > {log}
        spades.py --meta \
            -1 {input.r1} -2 {input.r2} \
            -o {params.outdir} \
            -t {threads} -m 16 2>> {log}
        echo "Assembly complete!" >> {log}
        """

# ============================================================================
# STEP 6: Calculate assembly statistics
# ============================================================================
rule assembly_stats:
    input:
        "results/assembly/contigs.fasta"
    output:
        "results/assembly/assembly_stats.txt"
    log:
        "logs/assembly_stats.log"
    shell:
        """
        echo "Calculating assembly statistics..." > {log}
        echo "Assembly Statistics for {input}" > {output}
        echo "=================================" >> {output}
        echo "" >> {output}
        
        # Count contigs
        echo -n "Number of contigs: " >> {output}
        grep -c "^>" {input} >> {output}
        
        # Get largest contig
        echo -n "Largest contig: " >> {output}
        awk '/^>/ {{if (seqlen) print seqlen; seq=""; seqlen=0; next}} \
             {{seq=seq$0; seqlen=length(seq)}} \
             END {{print seqlen}}' {input} | sort -rn | head -1 >> {output}
        
        # Total assembly length
        echo -n "Total assembly length: " >> {output}
        awk '/^>/ {{if (seqlen) total+=seqlen; seqlen=0; next}} \
             {{seqlen+=length($0)}} \
             END {{total+=seqlen; print total}}' {input} >> {output}
        
        echo "" >> {output}
        echo "Assembly statistics calculated!" >> {log}
        """

# ============================================================================
# STEP 7: Gene prediction with Prodigal
# ============================================================================
rule predict_genes:
    input:
        "results/assembly/contigs.fasta"
    output:
        proteins = "results/annotation/proteins.faa",
        genes = "results/annotation/genes.fna",
        gbk = "results/annotation/genes.gbk"
    log:
        "logs/prodigal.log"
    shell:
        """
        echo "Predicting genes with Prodigal..." > {log}
        prodigal -i {input} \
            -a {output.proteins} \
            -d {output.genes} \
            -o {output.gbk} \
            -f gbk -p meta 2>> {log}
        echo "Gene prediction complete!" >> {log}
        """

# ============================================================================
# STEP 8: Gene annotation with DIAMOND
# ============================================================================
rule annotate_genes:
    input:
        proteins = "results/annotation/proteins.faa",
        db = config["blast_database"]
    output:
        "results/annotation/spike_blast_results.txt"
    log:
        "logs/diamond_blast.log"
    threads: THREADS
    shell:
        """
        echo "Annotating genes with DIAMOND..." > {log}
        diamond blastp \
            --query {input.proteins} \
            --db {input.db} \
            --out {output} \
            --outfmt 6 \
            --max-target-seqs 5 \
            --evalue 1e-5 \
            --threads {threads} 2>> {log}
        echo "Annotation complete!" >> {log}
        """

# ============================================================================
# STEP 9: Phylogenetic analysis (16 sequences)
# ============================================================================
rule phylogenetic_analysis:
    input:
        sequences = config["phylo_sequences"]
    output:
        alignment = "results/phylogenetics/aligned_spikes_16.faa",
        tree = "results/phylogenetics/spike_tree_16.treefile"
    log:
        "logs/phylogenetics.log"
    threads: THREADS
    shell:
        """
        echo "Running phylogenetic analysis..." > {log}
        
        # Alignment with MAFFT
        echo "Aligning sequences with MAFFT..." >> {log}
        mafft --auto {input.sequences} > {output.alignment} 2>> {log}
        
        # Tree inference with IQ-TREE
        echo "Building phylogenetic tree with IQ-TREE..." >> {log}
        iqtree -s {output.alignment} \
            -m Blosum62+F+G4 \
            -bb 1000 \
            -nt {threads} \
            -pre results/phylogenetics/spike_tree_16 2>> {log}
        
        echo "Phylogenetic analysis complete!" >> {log}
        """

# ============================================================================
# STEP 10: Selection analysis
# ============================================================================
rule selection_analysis:
    input:
        alignment = "results/phylogenetics/aligned_spikes_16.faa"
    output:
        tree_fig = "results/phylogenetics/selection_analysis/phylogenetic_tree_PROFESSIONAL.png",
        selection_fig = "results/phylogenetics/selection_analysis/selection_analysis_results.png",
        heatmap = "results/phylogenetics/selection_analysis/rbd_alignment_heatmap.png",
        report = "results/phylogenetics/selection_analysis/SELECTION_ANALYSIS_REPORT.md"
    log:
        "logs/selection_analysis.log"
    shell:
        """
        echo "Running selection analysis..." > {log}
        bash scripts/phylogenetics/step9_selection_analysis/09.8_run_all.sh 2>> {log}
        echo "Selection analysis complete!" >> {log}
        """

# ============================================================================
# Utility rules
# ============================================================================

# Clean all results (use with caution!)
rule clean:
    shell:
        """
        rm -rf results/* data/clean/* logs/*
        echo "Cleaned all results, processed data, and logs"
        """

# Clean only intermediate files (keep final results)
rule clean_intermediate:
    shell:
        """
        rm -rf data/clean/*
        rm -rf results/assembly/K* results/assembly/tmp
        echo "Cleaned intermediate files"
        """

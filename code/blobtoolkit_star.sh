#!/usr/bin/env bash
set -euo pipefail

#--------------------------------------------------------------
## Script: blobtoolkit_star.sh
## Purpose: Download SRA reads, build STAR index, align reads, and index BAM for downstream BlobToolKit snail plots.

## Author: Rebecca Choi
## Date Created: July 2025
#--------------------------------------------------------------

SRA_ID="SRR26055770"

# Project directory on HPC (STAR index + outputs)
WORKDIR="../greenlandcockle"

# Reference genome FASTA (for STAR indexing)
GENOME_FASTA="${WORKDIR}/greenlandcockle.fna"

# FASTQs pathways
FASTQ_1="SRR26055770_1.fastq"
FASTQ_2="SRR26055770_2.fastq"

# STAR output prefix
OUT_PREFIX="${WORKDIR}/greenlandcockle_"

# Threads
THREADS_INDEX=16
THREADS_ALIGN=12


# Download FASTQs (run once, on HPC)
# Activate environment with SRA tools
conda activate sra_env

prefetch "${SRA_ID}"
fasterq-dump "${SRA_ID}"



# Build STAR genome index (on HPC; run once per genome)
# Activate environment with STAR + samtools
conda activate star_env

mkdir -p "${WORKDIR}"

STAR --runThreadN "${THREADS_INDEX}" \
  --runMode genomeGenerate \
  --genomeDir "${WORKDIR}" \
  --genomeFastaFiles "${GENOME_FASTA}" \
  --genomeSAindexNbases 14



# Align reads + index BAM (on HPC)
# Align paired-end reads and output sorted BAM
STAR --runThreadN "${THREADS_ALIGN}" \
  --genomeDir "${WORKDIR}" \
  --readFilesIn "${FASTQ_1}" "${FASTQ_2}" \
  --outFileNamePrefix "${OUT_PREFIX}" \
  --outSAMtype BAM SortedByCoordinate

# Create BAM index (.csi)
BAM="${OUT_PREFIX}Aligned.sortedByCoord.out.bam"
samtools index -c "${BAM}"
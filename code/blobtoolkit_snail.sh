#!/usr/bin/env bash
set -euo pipefail

#--------------------------------------------------------------
## Script: blobtoolkit_snail.sh
## Purpose: Generate BlobToolKit snail plots using Docker.
##
## Author: Rebecca Choi
## Date Created: July 2025
#--------------------------------------------------------------

# Generate snail plots using Docker
# Assumes the following files are in the current directory:
#   - greenlandcockle.fna
#   - greenlandcockle_Aligned.sortedByCoord.out.bam
#   - greenlandcockle_busco_full_table.tsv

docker run --rm \
  -v "$(pwd):/blobtoolkit/work" \
  genomehubs/blobtoolkit:latest \
  bash -lc "
    cd /blobtoolkit/work && \
    blobtools create --fasta greenlandcockle.fna datasets/greenlandcockle && \
    blobtools add --cov greenlandcockle_Aligned.sortedByCoord.out.bam datasets/greenlandcockle && \
    blobtools add --busco greenlandcockle_busco_full_table.tsv datasets/greenlandcockle && \
    blobtools view datasets/greenlandcockle --view snail --out snailplots
  "
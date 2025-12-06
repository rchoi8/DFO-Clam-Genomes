#!/bin/bash
#--------------------------------------------------------------
## Calculate Kimura Divergence (K2P) for Unclassified Repeats
## Purpose: This script extracts all RepeatMasker alignment entries corresponding to "Unknown" repeats and generates divergence summaries and a repeat landscape plot.
## Author: Rebecca Choi
## Date Created: June 2025
#--------------------------------------------------------------

## Set Paths and Genome Size
# RepeatMasker utilities folder (from conda environment)
RM_UTIL="$CONDA_PREFIX/share/RepeatMasker/util"
# Genome size in base pairs (update per species)
GENOME_SIZE=792970777  # Arctic surfclam genome size

## Extract "Unknown" Alignments
# Select all full alignment blocks with headers containing "#Unknown"
# RepeatMasker alignment blocks start with a line beginning with a number.
awk '
  /^[0-9].*#Unknown/ { inblock=1 }
  /^[0-9]/ && !/#Unknown/ && inblock { inblock=0 }
  inblock
' Arctic_Surf_Clam_Cleaned.fasta.align > TE_unclassified.full.align

## Generate Divergence Summary
# Calculate divergence (.div) and summary (.divsum)
perl -I"$RM_UTIL" \
  "$RM_UTIL/calcDivergenceFromAlign.pl" \
  -s TE_unclassified.div \
  TE_unclassified.full.align

## Create Repeat Landscape Plot
# Generate HTML landscape output
perl -I"$RM_UTIL" \
  "$RM_UTIL/createRepeatLandscape.pl" \
  -div TE_unclassified.div \
  -g "$GENOME_SIZE" \
  > TE_unclassified_landscape.html

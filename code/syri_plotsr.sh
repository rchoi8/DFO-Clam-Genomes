#!/usr/bin/env bash
#--------------------------------------------------------------
## Pairwise synteny plotting between Greenland cockle and Arctic surfclam

## Purpose: Top scaffolds from each genome are aligned and paired based on total aligned length, then analyzed with SyRI to identify structural variants and visualized as synteny plots with plotsr.
## Usage: bash syri_plotsr.sh [N] [PAIR] [THREADS]
## Example: bash syri_plotsr.sh 10 10 8

## Author: Rebecca Choi
## Date Created: January 2026
#--------------------------------------------------------------


# Exit if any command fails, any unset variable is used, or any command in a pipeline fails
set -euo pipefail

# Define genome labels, FASTA filenames, and output settings
REF_LABEL="Serripes_groenlandicus" # Reference genome label used in output names and plots
REF_FASTA="greenlandcockle.fna" # Reference genome FASTA file name
QRY_LABEL="Mactromeris_polynyma" # Query genome label used in output names and plots
QRY_FASTA="arcticsurfclam.fna" # Query genome FASTA file name

N="${1:-20}" # Number of top scaffolds to retain, default to 20 if no value is provided
PAIR="${2:-20}" # Number of scaffold pairs to analyze, default to 20 if no value is provided
THREADS="${3:-8}" # Number of threads, default to 8 if no value is provided

RUN="${REF_LABEL}_vs_${QRY_LABEL}_top${N}_pair${PAIR}" # Build run name from genome labels, scaffold count, and pair count
OUTDIR="RUN_${RUN}"
mkdir -p "$OUTDIR"
cd "$OUTDIR"

ln -sf "../$REF_FASTA" ref.fa # Create symbolic link to reference genome FASTA from output directory
ln -sf "../$QRY_FASTA" qry.fa # Create symbolic link to query genome FASTA from output directory


# Select top N scaffolds by length

# Sort reference scaffolds from longest to shortest
seqkit sort -l -r ref.fa -o ref.sorted.fa
# Keep first N scaffolds from sorted reference FASTA
seqkit head -n "$N" ref.sorted.fa -o ref_topN.fa
# Remove temporary sorted reference FASTA
rm -f ref.sorted.fa

# Repeat for query scaffolds
seqkit sort -l -r qry.fa -o qry.sorted.fa
seqkit head -n "$N" qry.sorted.fa -o qry_topN.fa
rm -f qry.sorted.fa

# Align top reference scaffolds against top query scaffolds
# Use asm20 preset, output CIGAR and alignment details, limit index size to 500M which ran smoothly
minimap2 -x asm20 -c --cs --eqx -t "$THREADS" -I 500M \
ref_topN.fa qry_topN.fa > aln_topN.paf

# Retain only cg:Z CIGAR tag required for SyRI parsing
# Set tab as output delimiter and extract reference/query IDs, coordinates, alignment length, and CIGAR tag
awk 'BEGIN{OFS="\t"}{
  cg=""
  for(i=13;i<=NF;i++) if($i ~ /^cg:Z:/) cg=$i
  if(cg!="") print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,cg
}' aln_topN.paf > aln_topN.clean.paf

# Apply one-to-one scaffold pairing for SyRI compatibility
# Sum aligned lengths for each reference-query scaffold pair and sort scaffold pairs by total aligned length from largest to smallest
# Pairs are selected by maximum total aligned length to avoid errors due to one-to-many mappings
awk 'BEGIN{FS=OFS="\t"}{
  ref=$6; qry=$1; alen=$11; sum[ref OFS qry]+=alen
} END{
  for(k in sum) print k, sum[k]
}' aln_topN.clean.paf | sort -k3,3nr > pair_sums.tsv

# Select highest-scoring unused reference and query scaffold pair and keep track of the used scaffolds so each scaffold occurs in only one pair
awk 'BEGIN{FS=OFS="\t"}
     !seen_ref[$1] && !seen_qry[$2] {
       seen_ref[$1]=1; seen_qry[$2]=1; print $1,$2,$3
     }' pair_sums.tsv > map_1to1.tsv

head -n "$PAIR" map_1to1.tsv > map.tsv

cut -f1 map.tsv > ref.ids # Write selected reference scaffold IDs to file
cut -f2 map.tsv > qry.ids # Write selected query scaffold IDs to file

seqkit grep -f ref.ids ref_topN.fa > ref.paired.fa # Extract selected reference scaffolds from top-N reference FASTA
seqkit grep -f qry.ids qry_topN.fa > qry.paired.fa # Extract selected query scaffolds from top-N query FASTA

# Rename scaffolds to paired placeholders expected by SyRI and assign shared pair IDs to reference-query scaffold pairs
# Placeholder names reflect alignment pairing, not scaffold order
awk 'BEGIN{FS=OFS="\t"} {printf("pair%02d\t%s\t%s\n", NR, $1, $2)}' map.tsv > rename_pair.tsv

# Replace reference scaffold IDs with pair IDs in reference FASTA
# Preserve sequence lines and replace matching FASTA headers
awk 'BEGIN{FS=OFS="\t"}
     NR==FNR{new[$2]=$1; next}
     /^>/{id=substr($0,2); sub(/ .*/,"",id);
           if(id in new){print ">"new[id]; next}}
     {print}' \
  rename_pair.tsv ref.paired.fa > ref.pair.fa

# Repeat for query
awk 'BEGIN{FS=OFS="\t"}
     NR==FNR{new[$3]=$1; next}
     /^>/{id=substr($0,2); sub(/ .*/,"",id);
           if(id in new){print ">"new[id]; next}}
     {print}' \
  rename_pair.tsv qry.paired.fa > qry.pair.fa

# Replace reference and query scaffold IDs in the PAF file with pair IDs so they match the renamed FASTA headers
awk 'BEGIN{FS=OFS="\t"}
     NR==FNR{refNew[$2]=$1; qryNew[$3]=$1; next}
     ($6 in refNew) && ($1 in qryNew) {
       $6=refNew[$6]; $1=qryNew[$1]; print
     }' \
  rename_pair.tsv aln_topN.clean.paf > aln_topN.pair.paf
  

# Identify structural rearrangements with SyRI

SYRI_PREFIX="syri_${RUN}_pair" # Set output filename prefix for SyRI results

# Run SyRI on paired scaffold alignments
# -F P: specify PAF input format
# --cigar: parse CIGAR strings from alignment file
# --nosnp: disable SNP identification and focus on structural variation
# --no-chrmatch: allow scaffold names without chromosome-style matching
syri \
  -c aln_topN.pair.paf \
  -r ref.pair.fa \
  -q qry.pair.fa \
  -F P \
  --cigar \
  --nosnp \
  -f \
  --no-chrmatch \
  --nc "$THREADS" \
  --prefix "$SYRI_PREFIX"


# Generate synteny plots (.pdf and .png) with plotsr using .tsv SyRI output

PWD_NOW="$(pwd)" # Store current output directory as absolute path so plotsr can find files

# Write reference and query FASTA paths, labels, and line widths to plotsr genome configuration
printf "%s\t%s\t%s\n%s\t%s\t%s\n" \
  "$PWD_NOW/ref.pair.fa" "$REF_LABEL" lw:1 \
  "$PWD_NOW/qry.pair.fa" "$QRY_LABEL" lw:1 \
> plotsr.genomes.tsv

# Generate PDF synteny plot from SyRI output

# -s 50000: plot structural rearrangements and syntenic blocks at 50 kb minimum size to plot only large-scale arrangements, reducing noise from small alignments
# -R: visually merge adjacent syntenic blocks not interrupted by rearrangements
# -H, -W, -f set plot height, width, and font size, respectively
plotsr \
--sr ${SYRI_PREFIX}syri.out \
--genomes plotsr.genomes.tsv \
-o "plotsr_${RUN}.pdf" \
-s 50000 \
-R \
-H 16 \
-W 18 \
-f 12 \
-b agg \
--log INFO

# Generate PNG synteny plot
plotsr \
--sr ${SYRI_PREFIX}syri.out \
--genomes plotsr.genomes.tsv \
-o "plotsr_${RUN}.png" \
-s 50000 \
-R \
-H 16 \
-W 18 \
-f 12 \
-d 900 \
-b agg \
--log INFO
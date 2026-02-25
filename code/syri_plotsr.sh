#!/usr/bin/env bash
#--------------------------------------------------------------
## Pairwise synteny plotting between Greenland cockle and Arctic surfclam

## Purpose: Top scaffolds from each genome are aligned and paired based on total aligned length, then analyzed with SyRI to identify structural variants and visualized as synteny plots with plotsr.
## Usage: bash syri_plotsr.sh [N] [PAIR] [THREADS]
## Example: bash syri_plotsr.sh 10 10 8

## Author: Rebecca Choi
## Date Created: January 2026
#--------------------------------------------------------------

set -euo pipefail

# Configure genomes, parameters, and outputs
REF_LABEL="Serripes_groenlandicus"
REF_FASTA="greenlandcockle.fna"
QRY_LABEL="Mactromeris_polynyma"
QRY_FASTA="arcticsurfclam.fna"

N="${1:-20}"        # top N scaffolds
PAIR="${2:-20}"     # paired scaffolds
THREADS="${3:-8}"   # threads

RUN="${REF_LABEL}_vs_${QRY_LABEL}_top${N}_pair${PAIR}"
OUTDIR="RUN_${RUN}"
mkdir -p "$OUTDIR"
cd "$OUTDIR"

ln -sf "../$REF_FASTA" ref.fa
ln -sf "../$QRY_FASTA" qry.fa



# Select top N scaffolds by length
seqkit sort -l -r ref.fa -o ref.sorted.fa
seqkit head -n "$N" ref.sorted.fa -o ref_topN.fa
rm -f ref.sorted.fa

seqkit sort -l -r qry.fa -o qry.sorted.fa
seqkit head -n "$N" qry.sorted.fa -o qry_topN.fa
rm -f qry.sorted.fa



# Align top scaffolds with minimap2 (reference as target)
minimap2 -x asm20 -c --cs --eqx -t "$THREADS" -I 500M \
  ref_topN.fa qry_topN.fa > aln_topN.paf



# Retain only the cg:Z CIGAR tag required by SyRI parsing
awk 'BEGIN{OFS="\t"}{
  cg=""
  for(i=13;i<=NF;i++) if($i ~ /^cg:Z:/) cg=$i
  if(cg!="") print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,cg
}' aln_topN.paf > aln_topN.clean.paf



# Apply one-to-one scaffold pairing for SyRI compatibility
# Pairs are selected by maximum total aligned length to avoid errors due to one-to-many mappings
awk 'BEGIN{FS=OFS="\t"}{
  ref=$6; qry=$1; alen=$11; sum[ref OFS qry]+=alen
} END{
  for(k in sum) print k, sum[k]
}' aln_topN.clean.paf | sort -k3,3nr > pair_sums.tsv

awk 'BEGIN{FS=OFS="\t"}
     !seen_ref[$1] && !seen_qry[$2] {
       seen_ref[$1]=1; seen_qry[$2]=1; print $1,$2,$3
     }' pair_sums.tsv > map_1to1.tsv

head -n "$PAIR" map_1to1.tsv > map.tsv



# Extract scaffolds from selected one-to-one pairs
cut -f1 map.tsv > ref.ids
cut -f2 map.tsv > qry.ids

seqkit grep -f ref.ids ref_topN.fa > ref.paired.fa
seqkit grep -f qry.ids qry_topN.fa > qry.paired.fa



# Rename scaffolds to paired placeholders expected by SyRI
# Placeholder names reflect alignment pairing, not scaffold order
awk 'BEGIN{FS=OFS="\t"} {printf("pair%02d\t%s\t%s\n", NR, $1, $2)}' map.tsv > rename_pair.tsv

awk 'BEGIN{FS=OFS="\t"}
     NR==FNR{new[$2]=$1; next}
     /^>/{id=substr($0,2); sub(/ .*/,"",id);
           if(id in new){print ">"new[id]; next}}
     {print}' \
  rename_pair.tsv ref.paired.fa > ref.pair.fa

awk 'BEGIN{FS=OFS="\t"}
     NR==FNR{new[$3]=$1; next}
     /^>/{id=substr($0,2); sub(/ .*/,"",id);
           if(id in new){print ">"new[id]; next}}
     {print}' \
  rename_pair.tsv qry.paired.fa > qry.pair.fa



# Update scaffold identifiers to match FASTA and alignment files
awk 'BEGIN{FS=OFS="\t"}
     NR==FNR{refNew[$2]=$1; qryNew[$3]=$1; next}
     ($6 in refNew) && ($1 in qryNew) {
       $6=refNew[$6]; $1=qryNew[$1]; print
     }' \
  rename_pair.tsv aln_topN.clean.paf > aln_topN.pair.paf



# Identify structural rearrangements with SyRI
SYRI_PREFIX="syri_${RUN}_pair"

# -F P: input alignment format is PAF
# --cigar: use CIGAR strings for alignment parsing
# --nosnp: skip SNP calling (structural variation only)
# --no-chrmatch: allow non-chromosomal scaffold pairing
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
PWD_NOW="$(pwd)"

printf "%s\t%s\t%s\n%s\t%s\t%s\n" \
  "$PWD_NOW/ref.pair.fa" "$REF_LABEL" lw:1 \
  "$PWD_NOW/qry.pair.fa" "$QRY_LABEL" lw:1 \
> plotsr.genomes.tsv


# -s 50000: plot only large-scale rearrangements, reducing noise from small alignment artifacts
# -R: visually merge adjacent syntenic blocks not interrupted by rearrangements
# .pdf output
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

# .png output
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

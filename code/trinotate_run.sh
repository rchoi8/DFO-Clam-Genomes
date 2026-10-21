#!/bin/bash
#--------------------------------------------------------------
## Trinotate Annotation Pipeline - Greenland cockle
## Purpose: This script performs Trinotate/transcriptome functional annotation using TransDecoder, DIAMOND, Pfam, SignalP, TMHMM.
## Author: Rebecca Choi
## Date Created: September 2025
#--------------------------------------------------------------

## Define Input Files & Paths
TRANSCRIPTS=/data/GreenCockle.Trinity.fasta
PEP=${TRANSCRIPTS}.transdecoder.pep
GENE_TRANS_MAP=${TRANSCRIPTS}.gene_trans_map
SWISSPROT_DMND=/usr/local/src/protein_databases/uniprot_sprot.dmnd
PFAM_DB=/usr/local/src/protein_databases/Pfam-A.hmm
SIGNALP_OUT=/data/GreenCockle_signalp
TMHMM_MODEL_DIR=/opt/tmhmm-2.0c
TRINOTATE_DB=Trinotate_GreenCockle.sqlite

## TransDecoder: ORF Prediction
# Identify long ORFs
TransDecoder.LongOrfs -t "$TRANSCRIPTS"
# Predict coding regions
TransDecoder.Predict -t "$TRANSCRIPTS"

## Homology Searches (BLASTX / BLASTP via DIAMOND)
# DIAMOND blastx
diamond blastx \
  -d "$SWISSPROT_DMND" \
  -q "$TRANSCRIPTS" \
  --outfmt 6 \
  --evalue 1e-5 \
  --max-target-seqs 1 \
  --threads 12 \
  > Greenland.diamond.blastx.tsv
# DIAMOND blastp
diamond blastp \
  -d "$SWISSPROT_DMND" \
  -q "$PEP" \
  --outfmt 6 \
  --evalue 1e-5 \
  --max-target-seqs 1 \
  --threads 12 \
  > Greenland.diamond.blastp.tsv

## Pfam Domain Search (HMMER)
hmmscan \
  --cpu 12 \
  --domtblout TrinotateGreenCocklePFAM.out \
  "$PFAM_DB" \
  "$PEP"

## Signal Peptide Prediction (SignalP 6)
python -m signalp.predict \
  --fastafile "$PEP" \
  --output_dir "$SIGNALP_OUT" \
  --organism euk \
  --mode fast \
  --format txt \
  --model_dir /opt/signalp6_fast/signalp-6-package/models

## TMHMM Transmembrane Domain Prediction
"$TMHMM_MODEL_DIR"/bin/decodeanhmm \
  "$TMHMM_MODEL_DIR"/lib/TMHMM2.0.model \
  -f "$TMHMM_MODEL_DIR"/lib/TMHMM2.0.options \
  -plp < "$PEP" \
  | perl "$TMHMM_MODEL_DIR"/bin/tmhmmformat.pl -short -noplot \
  > GreenCockle.tmhmm.short

## Initialize Trinotate SQLite Database
# Copy boilerplate Trinotate DB
cp -f "$TRINOTATE_DATA_DIR/TrinotateBoilerplate.sqlite" "$TRINOTATE_DB"
# Load transcript, gene mapping, and predicted peptide info
Trinotate --db "$TRINOTATE_DB" --init \
  --gene_trans_map "$GENE_TRANS_MAP" \
  --transcript_fasta "$TRANSCRIPTS" \
  --transdecoder_pep "$PEP"

## Load Annotation Evidence into Trinotate
# SwissProt homology
Trinotate --db "$TRINOTATE_DB" --LOAD_swissprot_blastx Greenland.diamond.blastx.tsv
Trinotate --db "$TRINOTATE_DB" --LOAD_swissprot_blastp Greenland.diamond.blastp.tsv
# PFAM domains
Trinotate --db "$TRINOTATE_DB" --LOAD_pfam TrinotateGreenCocklePFAM.out
# SignalP summary
Trinotate --db "$TRINOTATE_DB" --LOAD_signalp "$SIGNALP_OUT"/prediction_results.txt
# TMHMM transmembrane regions
Trinotate --db "$TRINOTATE_DB" --LOAD_tmhmmv2 GreenCockle.tmhmm.short

## Generate Final Trinotate Report
Trinotate --db "$TRINOTATE_DB" --report > Trinotate_Report_GreenlandCockle.tsv

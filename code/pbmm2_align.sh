#!/bin/bash

#align pacbio reads to reference genome with pbmm2 v26.2.99

#can sub in different files for GENOME
GENOME=GCA_032209615.1_xbMacPoly1_a1.0_genomic.fna

#Example with surf clam
pbmm2 index GCA_032209615.1_xbMacPoly1_a1.0_genomic.fna GCA_032209615.1_xbMacPoly1_a1.0_genomic.mmi

#Some genomes have more than 1 pacbio fastq dataset, so align them one at a time and then merge

pbmm2 align GCA_032209615.1_xbMacPoly1_a1.0_genomic.mmi SRR22741997.fastq SurfClam1.bam &&
bmm2 align GCA_032209615.1_xbMacPoly1_a1.0_genomic.mmi SRR23931590.fastq SurfClam2.bam

#merge into one bam

samtools merge surfclamAligned.bam SurfClam1.bam SurfClam2.bam
samtools sort -o sorted_surfclam.bam surfclamAligned.bam

#can use these bam files to generate coverage statistics for blobtoolkit snail and circle plots 
#Note - for blobtoolkit to create plots properly I had to set some port numbers:

ssh -L 8080:localhost:8080 -L 8000:localhost:8000 mcrg@mcrg-Precision-7920-Tower

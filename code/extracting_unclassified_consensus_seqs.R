## ---------------------------
## Extracting Unclassified Consensus Sequences

## Purpose: This script filters for the unclassified repeats' consensus sequences from Earl Grey outputs and outputs them in a FASTA file.

## Author: Rebecca Choi
## Date Created: June 17, 2025

## ---------------------------

#Load packages
#install.packages("tidyverse")
library(tidyverse)
#install.packages("styler")
library(styler)
#install.packages("BiocManager")
#BiocManager::install("Biostrings")
library(Biostrings)
#install.packages("stringr")
library(stringr)
#install.packages("dplyr")
library(dplyr)

#Read FASTA file from Earl Grey outputs, containing all consensus sequences in the genome
fasta_path <- "../repetitive_elements/Arctic_Surf_Clam_Cleaned-families.fa"
seqs <- readDNAStringSet(fasta_path)

#Extract repeat family from each header by extracting text between “#” and “(”
families <- names(seqs) %>%
  str_extract("(?<=#)[^\\(]+(?=\\()") %>%
  str_remove_all("\\s+")

#Make a repeat family counts table
family_counts_df <- tibble(Family = families) %>%
  count(Family, name = "Count", sort = TRUE)

#Check tibble
#print(family_counts_df) 

#Obtain FASTA with only Unknown (unclassified) sequences
unknown <- families=="Unknown"
writeXStringSet(
  seqs[unknown],
  filepath = "../repetitive_elements/arcticsurfclam_unclassified_seqs.fa")

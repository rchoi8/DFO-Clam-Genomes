#!/bin/bash
#SBATCH --account=def-skremer
#SBATCH --job-name=rm_k2p
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --output=rm_k2p-%j.out
#SBATCH --error=rm_k2p-%j.err
#SBATCH --mail-user=rchoi02@uoguelph.ca
#SBATCH --mail-type=BEGIN,END,FAIL

source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate repeatmasker_env

RepeatMasker \
  -pa 32 \
  -lib Arctic_Surf_Clam_Cleaned_combined_library.fasta \
  -dir . \
  -a Arctic_Surf_Clam_Cleaned.fasta

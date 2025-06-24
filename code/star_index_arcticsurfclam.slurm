#!/bin/bash
#SBATCH --account=def-skremer
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=20G
#SBATCH --job-name=star_arcticsurfclam_indices
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-user=rchoi02@uoguelph.ca
#SBATCH --mail-type=BEGIN,END,FAIL

source $HOME/miniconda3/bin/activate
conda activate star_env

STAR --runThreadN 16 \
     --runMode genomeGenerate \
     --genomeDir /scratch/rchoi02/star/arctic_surfclam/SRR24725107 \
     --genomeFastaFiles /scratch/rchoi02/star/arctic_surfclam/SRR24725107/arcticsurfclam.fna \
     --genomeSAindexNbases 14

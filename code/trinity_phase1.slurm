#!/bin/bash
#SBATCH --account=def-skremer
#SBATCH --time=7-00:00:00
#SBATCH --cpus-per-task=64
#SBATCH --mem=250G
#SBATCH --ntasks=1
#SBATCH --job-name=trin_phase1
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-user=rchoi02@uoguelph.ca
#SBATCH --mail-type=BEGIN,END,FAIL

source $HOME/miniconda3/bin/activate
conda activate trinity_env

Trinity \
  --seqType fq \
  --left SRR26055770_1.fastq \
  --right SRR26055770_2.fastq \
  --trimmomatic \
  --max_memory 250G \
  --no_distributed_trinity_exec \
  --output /scratch/rchoi02/greenland_cockle/trinity_stepwise
 

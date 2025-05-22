#!/bin/bash
#SBATCH --account=def-skremer
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --job-name=metazoa_arctic_12
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-user=rchoi02@uoguelph.ca
#SBATCH --mail-type=BEGIN,END,FAIL

source $HOME/miniconda3/bin/activate
conda activate busco_conda

busco -i /home/rchoi02/projects/def-skremer/rchoi02/data/ncbi_arcticsurfclam/data/arcticsurfclam.fna -m genome -l metazoa_odb12 -c $SLURM_CPUS_PER_TASK --metaeuk -o metazoa_arctic_12


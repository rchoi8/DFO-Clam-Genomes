#!/bin/bash
#SBATCH --job-name=of_all
#SBATCH --account=def-skremer
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=128G
#SBATCH --time=7-00:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=rchoi02@uoguelph.ca
#SBATCH --output=logs/of_%j.out
#SBATCH --error=logs/of_%j.err

set -euo pipefail
mkdir -p logs

## Load Modules and Activate Conda Env
module --force purge
module load StdEnv/2023
module load diamond/2.1.10
module load mafft/7.526
source ~/miniconda3/etc/profile.d/conda.sh
conda activate of3_env

## Define Paths
PYTHON=/home/rchoi02/miniconda3/envs/of3_env/bin/python
ORTHO_BIN=/home/rchoi02/miniconda3/envs/of3_env/bin/orthofinder
export PATH=/home/rchoi02/miniconda3/envs/of3_env/bin:$PATH
unset MAFFT_BINARIES
export OMP_NUM_THREADS=1
BASE=/scratch/rchoi02/phylogeny/data/protein_seqs/primary_transcripts

## Run Orthofinder
$PYTHON "$ORTHO_BIN" \
  -f "${BASE}" \
  -M msa -A mafft \
  -t "${SLURM_CPUS_PER_TASK}" \
  -a 32 

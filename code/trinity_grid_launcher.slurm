#!/bin/bash
#SBATCH --account=def-skremer
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --job-name=trinity_grid_launcher
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-user=rchoi02@uoguelph.ca
#SBATCH --mail-type=BEGIN,END,FAIL

cd /scratch/rchoi02/greenland_cockle/trinity_stepwise
source $HOME/miniconda3/bin/activate
conda activate trinity_env

Trinity \
  --seqType fq \
  --left insilico_read_normalization/left.norm.fq \
  --right insilico_read_normalization/right.norm.fq \
  --output /scratch/rchoi02/greenland_cockle/trinity_stepwise \
  --max_memory 100G \
  --CPU 16 \
  --grid_exec /scratch/rchoi02/greenland_cockle/trinity_stepwise/submit_grid_job.sh

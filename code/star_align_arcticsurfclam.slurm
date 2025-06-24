#!/bin/bash
#SBATCH --account=def-skremer
#SBATCH --time=3:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem=48G
#SBATCH --job-name=star_align_arcticsurfclam
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-user=rchoi02@uoguelph.ca
#SBATCH --mail-type=BEGIN,END,FAIL

source $HOME/miniconda3/bin/activate
conda activate star_env

STAR --runThreadN 12 \
     --genomeDir /scratch/rchoi02/star/arctic_surfclam/SRR24725107 \
     --readFilesIn /scratch/rchoi02/star/arctic_surfclam/SRR24725107/SRR24725107_1.fastq \
                   /scratch/rchoi02/star/arctic_surfclam/SRR24725107/SRR24725107_2.fastq \
     --outFileNamePrefix /scratch/rchoi02/star/arctic_surfclam/SRR24725107/arcticsurfclam_ \
     --outSAMtype BAM SortedByCoordinate

samtools index -c /scratch/rchoi02/star/arctic_surfclam/SRR24725107/arcticsurfclam_Aligned.sortedByCoord.out.bam

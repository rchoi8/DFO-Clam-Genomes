#!/bin/bash

# File containing list of Trinity commands to run
COMMAND_LIST=$1

# Check input
if [[ ! -f "$COMMAND_LIST" ]]; then
  echo "ERROR: Command list '$COMMAND_LIST' not found"
  exit 1
fi

# Split large command file into batches of 10000 commands each
split -l 10000 "$COMMAND_LIST" cmd_batch_

# Submit each batch to SLURM as an individual job
for BATCH in cmd_batch_*; do
  ABS_PATH=$(realpath "$BATCH")
  sbatch <<EOF
#!/bin/bash
#SBATCH --account=def-skremer
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --job-name=trin_grid
#SBATCH --output=trin_grid_%j.out
#SBATCH --error=trin_grid_%j.err
#SBATCH --mail-user=rchoi02@uoguelph.ca
#SBATCH --mail-type=FAIL,END

cd /scratch/rchoi02/greenland_cockle/trinity_stepwise
xargs -P 8 -I {} bash -c '{}' < "$ABS_PATH"
EOF
done

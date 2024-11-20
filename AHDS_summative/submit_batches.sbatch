#!/bin/bash
#SBATCH --job-name=fetch_articles
#SBATCH --output=logs/fetch_articles_%A_%a.log
#SBATCH --error=logs/fetch_articles_%A_%a.err
#SBATCH --array=0-9            # Adjust based on the number of batches
#SBATCH --time=00:10:00        # Max time for each batch
#SBATCH --cpus-per-task=1      # CPUs per task
#SBATCH --mem=1G               # Memory per task

# Load environment (if needed)
module load curl

# Arguments
PMID_BATCH_DIR="data/pmid_batches"
OUTPUT_DIR="data/articles"
BATCH_FILE=$(ls $PMID_BATCH_DIR | sed -n "$((SLURM_ARRAY_TASK_ID + 1))p")
OUTPUT_FILE="$OUTPUT_DIR/batch-${SLURM_ARRAY_TASK_ID}.xml"

# Execute the fetch script
bash scripts/fetch_articles.sh "$PMID_BATCH_DIR/$BATCH_FILE" "$OUTPUT_FILE"

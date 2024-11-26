#!/bin/bash

# Exit if any command fails
set -e

# SLURM Job Submission Directives
#SBATCH --job-name=AHDS_2553055          # Name of the job
#SBATCH --partition=teach_cpu            # Partition name
#SBATCH --nodes=1                        # Number of nodes
#SBATCH --ntasks=1                       # Number of tasks (typically the same as nodes for simple jobs)
#SBATCH --cpus-per-task=1                # Number of cores per task
#SBATCH --mem=16G                        # Memory per node
#SBATCH --time=12:00:00                  # Time limit hrs:min:sec
#SBATCH --output=AHDS_2553055_%j.log     # Standard output and error log
#SBATCH --account=SSCM033324

echo "Job started on $(date)"  # Using $(...) for command substitution

# Conda environment
source ~/initConda.sh
conda activate AHDS-env

# Clear the original data
snakemake clean

# Execute the Snakemake pipeline
snakemake

echo "Job ended on $(date)"  # Consistency in command substitution

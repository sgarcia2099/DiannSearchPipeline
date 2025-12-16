#!/bin/bash
#SBATCH -A bsd
#SBATCH -p burst
#SBATCH --qos=default
#SBATCH -t 00:10:00
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --mem=16g
#SBATCH -J hpc_pipeline_test
#SBATCH --output=logs/test_pipeline_%j.out
#SBATCH --error=logs/test_pipeline_%j.err

set -euo pipefail

# Define directories and paths
BASE="/lustre/or-scratch/cades-bsd/$USER"
SINGULARITY_TMPDIR="$BASE/tmp"
SINGULARITY_CACHEDIR="$BASE/cache"
RESULT_DIR="$BASE/test_results"
RAWFILES_DIR="$BASE/rawfiles"
LOG_DIR="logs"
CONTAINER_IMAGE="thermorawfileparser_1.4.5--h05cac1d_1.sif"
TEST_FILE="$RESULT_DIR/result.txt"

# Create necessary directories
mkdir -p \
  "$SINGULARITY_TMPDIR" \
  "$SINGULARITY_CACHEDIR" \
  "$RESULT_DIR" \
  "$LOG_DIR"

singularity pull --dir $SINGULARITY_CACHEDIR docker://quay.io/biocontainers/thermorawfileparser:1.4.5--h05cac1d_1

# Check if key utilities and dependencies are available
for cmd in singularity nextflow; do
  if ! command -v $cmd &>/dev/null; then
    echo "ERROR: Command $cmd is not installed or available in PATH!"
    exit 1
  fi
done
echo "Required commands are available: singularity, nextflow."

# Check if the SLURM environment is active
if [[ -z "${SLURM_JOB_ID:-}" ]]; then
  echo "ERROR: Script is not running in a SLURM job environment!"
  exit 1
fi
echo "SLURM environment is active. Job ID: $SLURM_JOB_ID"

# Check for required input directory
if [[ ! -d "$RAWFILES_DIR" ]]; then
  echo "ERROR: Raw files directory $RAWFILES_DIR does not exist! Please ensure input files are in place."
  exit 1
fi
echo "Raw files directory exists."

# Verify the container image
if ! singularity inspect "$CONTAINER_IMAGE" &>/dev/null; then
  echo "ERROR: Container image $CONTAINER_IMAGE not found locally or is corrupted!"
  exit 1
fi
echo "Container image is valid and available."

# Run a simple command inside the container to validate it works
singularity exec "$CONTAINER_IMAGE" bash -c "echo 'HPC Test Passed' > $TEST_FILE"

# Verify that the test file is created
if [[ ! -f "$TEST_FILE" ]]; then
  echo "ERROR: Failed to generate $TEST_FILE inside $RESULT_DIR!"
  exit 1
fi
echo "Test file successfully created: $TEST_FILE"

# Final confirmation
echo "HPC test completed successfully. Your environment and container are ready for the pipeline."
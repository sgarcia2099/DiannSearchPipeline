#!/bin/bash

set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "Error: This script requires the DIA-NN version as an argument (e.g., ./submit_diann.sh 2.3.1)."
    exit 1
fi

DIANN_VERSION="$1"

BASE="/lustre/or-scratch/cades-bsd/$USER"
REPO_DIR="$HOME/github/DiannSearchPipeline"

# Fixed container path
CONTAINER_SIF="/lustre/or-scratch/cades-bsd/jkg/cache/diann_container.sif"

# Verify container exists before proceeding
if [ ! -f "$CONTAINER_SIF" ]; then
    echo "Error: Container not found at $CONTAINER_SIF"
    echo "Please ensure diann_container.sif exists in /lustre/or-scratch/cades-bsd/jkg/cache/"
    exit 1
fi
echo "Using container: $CONTAINER_SIF"

# Create timestamp for unique job directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
JOB_DIR="$BASE/diann_job_${TIMESTAMP}"

echo "Creating job directory: $JOB_DIR"
mkdir -p "$JOB_DIR"

# Set up Apptainer directories
export APPTAINER_TMPDIR="$BASE/tmp"
export APPTAINER_CACHEDIR="$BASE/cache"

mkdir -p \
  "$APPTAINER_TMPDIR" \
  "$APPTAINER_CACHEDIR"

# Create job-specific directories first (logs must exist for SBATCH output)
mkdir -p "$JOB_DIR/logs" "$JOB_DIR/results" "$JOB_DIR/work"

# Generate prep script for file copying
PREP_SCRIPT="$JOB_DIR/prepare_job.sbatch"

cat > "$PREP_SCRIPT" <<EOF
#!/bin/bash
#SBATCH -A bsd
#SBATCH -p burst
#SBATCH --qos=default
#SBATCH -t 1:00:00
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --mem=8g
#SBATCH -J diann_prep_${TIMESTAMP}
#SBATCH --output=${JOB_DIR}/logs/prep_%j.out
#SBATCH --error=${JOB_DIR}/logs/prep_%j.err

set -euxo pipefail

BASE="/lustre/or-scratch/cades-bsd/\$USER"
REPO_DIR="\$HOME/github/DiannSearchPipeline"
JOB_DIR="${JOB_DIR}"

# Sanity check for RAW files in staging area
if [ ! -d "\$BASE/rawfiles" ] || [ -z "\$(ls -A "\$BASE/rawfiles" 2>/dev/null)" ]; then
    echo "Error: No .raw files found in \$BASE/rawfiles."
    exit 1
fi

# Copy all needed files into job directory (self-contained)
echo "Copying files into job directory..."
cp -r --no-dereference "\$BASE/rawfiles" "${JOB_DIR}/rawfiles"
cp -r --no-dereference "\$BASE/fasta" "${JOB_DIR}/fasta"
cp -r --no-dereference "\$BASE/configs" "${JOB_DIR}/configs"
cp "\$REPO_DIR/main.nf" "${JOB_DIR}/"
cp "\$REPO_DIR/nextflow.config" "${JOB_DIR}/"

# Verify files copied successfully
echo "Verifying files copied successfully..."
if [ ! -d "${JOB_DIR}/rawfiles" ] || [ -z "\$(ls -A "${JOB_DIR}/rawfiles" 2>/dev/null)" ]; then
    echo "Error: Failed to copy rawfiles to job directory"
    exit 1
fi
if [ ! -d "${JOB_DIR}/fasta" ] || [ -z "\$(ls -A "${JOB_DIR}/fasta" 2>/dev/null)" ]; then
    echo "Error: Failed to copy fasta to job directory"
    exit 1
fi
if [ ! -d "${JOB_DIR}/configs" ] || [ -z "\$(ls -A "${JOB_DIR}/configs" 2>/dev/null)" ]; then
    echo "Error: Failed to copy configs to job directory"
    exit 1
fi

echo "Prep job complete: files staged"
EOF

echo "Submitting prep job for file staging..."
PREP_JOB_ID=$(sbatch --parsable "$PREP_SCRIPT")
echo "Prep job submitted with ID: $PREP_JOB_ID"

# Generate the main Nextflow SBATCH script
SBATCH_FILE="$JOB_DIR/run_diann.sbatch"

cat > "$SBATCH_FILE" <<EOF
#!/bin/bash
#SBATCH -A bsd
#SBATCH -p burst
#SBATCH --constraint=high_mem_cd
#SBATCH --qos=default
#SBATCH -t 1-00:00:00
#SBATCH --nodes=1
#SBATCH -c 32
#SBATCH --mem=125g
#SBATCH -J diann_${TIMESTAMP}
#SBATCH --output=$JOB_DIR/logs/nf_%j.out
#SBATCH --error=$JOB_DIR/logs/nf_%j.err
#SBATCH --dependency=afterany:${PREP_JOB_ID}

set -euxo pipefail

# Change to job directory
cd "$JOB_DIR"

# Set Apptainer environment - use absolute job directory paths for complete isolation
export APPTAINER_TMPDIR="/lustre/or-scratch/cades-bsd/jkg/tmp"
export APPTAINER_CACHEDIR="/lustre/or-scratch/cades-bsd/jkg/cache"
export APPTAINER_BINDPATH="$JOB_DIR:$JOB_DIR"

CONTAINER_SIF="/lustre/or-scratch/cades-bsd/jkg/cache/diann_container.sif"

# Run Nextflow with absolute job-specific paths
# All input files are now isolated in JOB_DIR and won't be affected by changes to staging areas
nextflow run main.nf \\
    --raw_dir "$JOB_DIR/rawfiles" \\
    --fasta_dir "$JOB_DIR/fasta" \\
    --config_dir "$JOB_DIR/configs" \\
    --outdir "$JOB_DIR/results" \\
    --diann_version "$DIANN_VERSION" \\
    --container_sif "\$CONTAINER_SIF" \\
    -work-dir "$JOB_DIR/work" \\
    -resume
EOF

# Submit the main SBATCH script (will wait for prep job to complete)
echo "Submitting main Nextflow job (will wait for prep job to complete)..."
echo "Nextflow job file: $SBATCH_FILE"

# Use afterany instead of afterok to handle any prep job state
# This ensures main job runs once prep job finishes, even if prep has non-zero exit
# The prep script includes validation, so failures will be caught there
MAIN_JOB_ID=$(sbatch --parsable --dependency=afterany:${PREP_JOB_ID} "$SBATCH_FILE")
echo "Nextflow job submitted with ID: $MAIN_JOB_ID (depends on prep job $PREP_JOB_ID)"

echo ""
echo "Job directory: $JOB_DIR"
echo "Prep job: $PREP_JOB_ID"
echo "Main job: $MAIN_JOB_ID"
echo "Monitor prep job logs: $JOB_DIR/logs/prep_*.out"
echo "Monitor main job logs: $JOB_DIR/logs/nf_*.out"
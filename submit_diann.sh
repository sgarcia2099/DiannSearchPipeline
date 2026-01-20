#!/bin/bash

set -euxo pipefail

if [ "$#" -eq 0 ]; then
    echo "Error: This script requires the DIA-NN version as an argument (e.g., ./submit_diann.sh 2.3.1)."
    exit 1
fi

DIANN_VERSION="$1"

BASE="/lustre/or-scratch/cades-bsd/$USER"
REPO_DIR="$HOME/github/DiannSearchPipeline"

# Create timestamp for unique job directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
JOB_DIR="$BASE/diann_job_${TIMESTAMP}"

echo "Creating job directory: $JOB_DIR"
mkdir -p "$JOB_DIR"

# Global Apptainer directories (shared across all jobs)
# Note: Only bind the job directory, not the entire BASE to prevent cross-job interference
export APPTAINER_TMPDIR="$BASE/tmp"
export APPTAINER_CACHEDIR="$BASE/cache"
export APPTAINER_BINDPATH="$JOB_DIR:$JOB_DIR"

mkdir -p \
  "$APPTAINER_TMPDIR" \
  "$APPTAINER_CACHEDIR"

# Pull or verify container exists (pull once, reuse forever)
CONTAINER_SIF="$APPTAINER_CACHEDIR/diannpipeline_${DIANN_VERSION}.sif"
if [ ! -f "$CONTAINER_SIF" ]; then
    echo "Container not found. Pulling: docker://garciasarah2099/diannpipeline:${DIANN_VERSION}"
    apptainer pull "$CONTAINER_SIF" "docker://garciasarah2099/diannpipeline:${DIANN_VERSION}"
    echo "Container stored: $CONTAINER_SIF"
else
    echo "Using existing container: $CONTAINER_SIF"
fi
echo ""

# Sanity check for RAW files in staging area
if [ ! -d "$BASE/rawfiles" ] || [ -z "$(ls -A "$BASE/rawfiles" 2>/dev/null)" ]; then
    echo "Error: No .raw files found in $BASE/rawfiles."
    echo "Please place raw files in $BASE/rawfiles before submitting."
    exit 1
fi

# Copy all needed files into job directory (self-contained)
# Use absolute paths and deep copy to ensure complete isolation from staging area
echo "Copying files into job directory..."
cp -r --no-dereference "$BASE/rawfiles" "$JOB_DIR/rawfiles"
cp -r --no-dereference "$BASE/fasta" "$JOB_DIR/fasta"
cp -r --no-dereference "$BASE/configs" "$JOB_DIR/configs"
cp "$REPO_DIR/main.nf" "$JOB_DIR/"
cp "$REPO_DIR/nextflow.config" "$JOB_DIR/"

echo "Verifying files copied successfully..."
if [ ! -d "$JOB_DIR/rawfiles" ] || [ -z "$(ls -A "$JOB_DIR/rawfiles" 2>/dev/null)" ]; then
    echo "Error: Failed to copy rawfiles to job directory"
    exit 1
fi
if [ ! -d "$JOB_DIR/fasta" ] || [ -z "$(ls -A "$JOB_DIR/fasta" 2>/dev/null)" ]; then
    echo "Error: Failed to copy fasta to job directory"
    exit 1
fi
if [ ! -d "$JOB_DIR/configs" ] || [ -z "$(ls -A "$JOB_DIR/configs" 2>/dev/null)" ]; then
    echo "Error: Failed to copy configs to job directory"
    exit 1
fi

# Create job-specific directories
mkdir -p "$JOB_DIR/logs" "$JOB_DIR/results" "$JOB_DIR/work"

echo "Job directory setup complete: $JOB_DIR"
echo ""

# Generate the SBATCH script
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

set -euxo pipefail

# Change to job directory
cd "$JOB_DIR"
# Set Apptainer environment - use absolute job directory paths for complete isolation
export APPTAINER_TMPDIR="$APPTAINER_TMPDIR"
export APPTAINER_CACHEDIR="$APPTAINER_CACHEDIR"
export APPTAINER_BINDPATH="$JOB_DIR:$JOB_DIR"

# Run Nextflow with absolute job-specific paths
# All input files are now isolated in JOB_DIR and won't be affected by changes to staging areas
nextflow run main.nf \\
    --raw_dir "$(cd "$JOB_DIR/rawfiles" 2>/dev/null && pwd || echo "$JOB_DIR/rawfiles")" \\
    --fasta_dir "$(cd "$JOB_DIR/fasta" 2>/dev/null && pwd || echo "$JOB_DIR/fasta")" \\
    --config_dir "$(cd "$JOB_DIR/configs" 2>/dev/null && pwd || echo "$JOB_DIR/configs")" \\
    --outdir "$JOB_DIR/results" \\
    --diann_version "$DIANN_VERSION" \\
    --container_sif "$CONTAINER_SIF" \\
    -work-dir "$JOB_DIR/work" \\
    -resumeir "$JOB_DIR/work" \\
    -resume
EOF

# Submit the SBATCH script
echo "Submitting SLURM job: $SBATCH_FILE"
echo "Job directory: $JOB_DIR"
sbatch "$SBATCH_FILE"

echo ""
echo "Job $JOB_DIR submitted successfully!"
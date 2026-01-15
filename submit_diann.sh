#!/bin/bash

set -euxo pipefail

if [ "$#" -eq 0 ]; then
    echo "Error: This script requires the DIA-NN version as an argument (e.g., ./submit_diann.sh 2.3.1)."
    exit 1
fi

DIANN_VERSION="$1"

BASE="/lustre/or-scratch/cades-bsd/$USER"

# Directories to use
export APPTAINER_TMPDIR="$BASE/tmp"
export APPTAINER_CACHEDIR="$BASE/cache"
export APPTAINER_BINDPATH="$BASE"

mkdir -p \
  "$APPTAINER_TMPDIR" \
  "$APPTAINER_CACHEDIR" \
  logs \
  "$BASE/results" \

# Sanity check for RAW files
if [ ! -d "$BASE/rawfiles" ] || [ -z "$(ls -A "$BASE/rawfiles" 2>/dev/null)" ]; then
    echo "Error: No .raw files found in $BASE/rawfiles."
    exit 1
fi

# Generate the SBATCH script
SBATCH_FILE="run_diann.sbatch"

cat > "$SBATCH_FILE" <<EOF
#!/bin/bash
#SBATCH -A bsd
#SBATCH -p batch
#SBATCH --qos=bsd-batch
#SBATCH -t 1-00:00:00
#SBATCH --nodes=1
#SBATCH -c 32
#SBATCH --mem=125g
#SBATCH -J diann_nf
#SBATCH --output=logs/nf_%j.out
#SBATCH --error=logs/nf_%j.err

set -euxo pipefail

# Run Nextflow
nextflow run main.nf \
    --raw_dir "$BASE/rawfiles" \
    --outdir "$BASE/results" \
    --diann_version "$DIANN_VERSION" \
    -resume
EOF

# Submit the SBATCH script
echo "Submitting SLURM job: $SBATCH_FILE"
sbatch "$SBATCH_FILE"
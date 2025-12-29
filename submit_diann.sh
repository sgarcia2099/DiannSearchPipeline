#!/bin/bash

set -euo pipefail

BASE="/lustre/or-scratch/cades-bsd/$USER"

# Directories to use
export SINGULARITY_TMPDIR="$BASE/tmp"
export SINGULARITY_CACHEDIR="$BASE/cache"

mkdir -p \
  "$SINGULARITY_TMPDIR" \
  "$SINGULARITY_CACHEDIR" \
  logs \
  "$BASE/results"

# Generate the SBATCH script
SBATCH_FILE="run_diann.sbatch"

cat > "$SBATCH_FILE" << EOF
#!/bin/bash
#SBATCH -A bsd
#SBATCH -p burst
#SBATCH --qos=default
#SBATCH -t 1-00:00:00
#SBATCH --nodes=1
#SBATCH -c 32
#SBATCH --mem=128g
#SBATCH -J diann_nf
#SBATCH --output=logs/nf_%j.out
#SBATCH --error=logs/nf_%j.err

set -euo pipefail

# Run Nextflow
nextflow run main.nf \
    --raw_dir "$BASE/rawfiles" \
    --outdir "$BASE/results" \
    --diann_version "$1" \
    -resume \
EOF

# Submit the SBATCH script
echo "Submitting SLURM job: $SBATCH_FILE"
sbatch "$SBATCH_FILE"

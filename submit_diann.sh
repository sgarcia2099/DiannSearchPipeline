#!/bin/bash

mkdir -p \
/lustre/or-scratch/cades-bsd/$USER/results \
/lustre/or-scratch/cades-bsd/$USER/singularity_cache \
/lustre/or-scratch/cades-bsd/$USER/apptainer_tmp \
/lustre/or-scratch/cades-bsd/$USER/apptainer_cache

set -euo pipefail

BASE="/lustre/or-scratch/cades-bsd/$USER"

# Directories to use
export NXF_SINGULARITY_CACHEDIR="$BASE/singularity_cache"
export APPTAINER_TMPDIR="$BASE/apptainer_tmp"
export APPTAINER_CACHEDIR="$BASE/apptainer_cache"

mkdir -p \
  "$NXF_SINGULARITY_CACHEDIR" \
  "$APPTAINER_TMPDIR" \
  "$APPTAINER_CACHEDIR" \
  logs \
  "$BASE/results"

# Generate the SBATCH script
SBATCH_FILE="run_diann.sbatch"

cat > "$SBATCH_FILE" << EOF
#!/bin/bash
#SBATCH -A bsd
#SBATCH -p burst
#SBATCH --qos=default
#SBATCH -t 10:00:00
#SBATCH --nodes=1
#SBATCH -c 4
#SBATCH --mem=11g
#SBATCH -J diann_nf
#SBATCH --output=logs/nf_%j.out
#SBATCH --error=logs/nf_%j.err

set -euo pipefail

# Run Nextflow
nextflow run main.nf \
    --raw_dir "$BASE/rawfiles" \
    --outdir "$BASE/results" \
    -resume \
    -with-singularity quay.io/biocontainers/thermorawfileparser:1.4.5--h05cac1d_1
EOF

# Submit the SBATCH script
echo "Submitting SLURM job: $SBATCH_FILE"
sbatch "$SBATCH_FILE"

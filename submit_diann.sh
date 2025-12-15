#!/bin/bash
#SBATCH -A bsd
#SBATCH -p burst
#SBATCH --qos=default
#SBATCH -t 10:00:00
#SBATCH --nodes=1
#SBATCH -c 1
#SBATCH --mem=2g
#SBATCH -J diann_nf
#SBATCH --output=logs/nf_%j.out
#SBATCH --error=logs/nf_%j.err

set -euo pipefail

BASE="/lustre/or-scratch/cades-bsd/$USER"

export NXF_SINGULARITY_CACHEDIR="$BASE/singularity_cache"
export APPTAINER_TMPDIR="$BASE/apptainer_tmp"
export APPTAINER_CACHEDIR="$BASE/apptainer_cache"

mkdir -p \
  "$NXF_SINGULARITY_CACHEDIR" \
  "$APPTAINER_TMPDIR" \
  "$APPTAINER_CACHEDIR" \
  logs \
  "$BASE/results"

nextflow run main.nf \
    --raw_dir "$BASE/rawfiles" \
    --outdir  "$BASE/results" \
    -resume \
    -with-singularity

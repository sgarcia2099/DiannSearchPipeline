#!/bin/bash
set -euo pipefail

echo -e "Initializing\n"

RAW_DIR="/lustre/or-scratch/cades-bsd/$USER/rawfiles"
CONTAINER="quay.io/biocontainers/thermorawfileparser:1.4.5--h05cac1d_1"
OUT_BASE="/lustre/or-scratch/cades-bsd/$USER/results"
WORK_DIR="/lustre/or-scratch/cades-bsd/$USER/work"
STASH_DIR="/lustre/or-scratch/cades-bsd/$USER/stash"

# Apptainer / Singularity paths (CRITICAL on CADES)
SINGULARITY_CACHE="/lustre/or-scratch/cades-bsd/$USER/singularity_cache"
APPTAINER_TMP="/lustre/or-scratch/cades-bsd/$USER/apptainer_tmp"
APPTAINER_CACHE="/lustre/or-scratch/cades-bsd/$USER/apptainer_cache"

echo -e "Making directories...\n"

mkdir -p \
    logs \
    "$OUT_BASE" \
    "$WORK_DIR" \
    "$STASH_DIR" \
    "$SINGULARITY_CACHE" \
    "$APPTAINER_TMP" \
    "$APPTAINER_CACHE"

echo -e "Parsing through .raw files...\n"

for RAW in "$RAW_DIR"/*.raw; do
    BASENAME=$(basename "$RAW" .raw)
    OUT_DIR="${OUT_BASE}/${BASENAME}"
    mkdir -p "$OUT_DIR"

    SBATCH_FILE="run_${BASENAME}.sbatch"

cat > "$SBATCH_FILE" << EOF
#!/bin/bash
#SBATCH -A bsd
#SBATCH -p burst
#SBATCH --qos=default
#SBATCH -t 10:00:00
#SBATCH --nodes=1
#SBATCH -c 4
#SBATCH --mem=11g
#SBATCH -J diann_${BASENAME}
#SBATCH --output=logs/${BASENAME}_%j.out
#SBATCH --error=logs/${BASENAME}_%j.err

set -euo pipefail

# ----------------------------
# Apptainer / Singularity FIX
# ----------------------------
export NXF_SINGULARITY_CACHEDIR="${SINGULARITY_CACHE}"
export APPTAINER_TMPDIR="${APPTAINER_TMP}"
export APPTAINER_CACHEDIR="${APPTAINER_CACHE}"

# JVM tuning for Nextflow
export NXF_OPTS="-Xms10g -Xmx10g"

# Optional: avoid accidental HOME pollution
export NXF_HOME="${WORK_DIR}/.nextflow"

# ----------------------------
# Run workflow
# ----------------------------
nextflow -C nextflow.config run main.nf \
    --raw_file "$RAW" \
    --outdir "$OUT_DIR" \
    -resume \
    -with-singularity \
    -with-timeline ${OUT_DIR}/timeline.html \
    -with-dag ${OUT_DIR}/flowchart.html \
    -with-report ${OUT_DIR}/report.html \
    -with-trace

mv trace* "${OUT_DIR}/" 2>/dev/null || true
EOF

    echo "Submitting: $SBATCH_FILE"
    sbatch "$SBATCH_FILE"

done


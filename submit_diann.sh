#!/bin/bash

RAW_DIR="/lustre/or-scratch/cades-bsd/$USER/rawfiles"
CONTAINER="containers/TRFP.sif"
OUT_BASE="/lustre/or-scratch/cades-bsd/$USER/results"

mkdir -p logs
mkdir -p "$OUT_BASE"

for RAW in "$RAW_DIR"/*.raw; do
    BASENAME=$(basename "$RAW" .raw)
    OUT_DIR="${OUT_BASE}/${BASENAME}"
    mkdir -p "$OUT_DIR"

    SBATCH_FILE="run_${BASENAME}.sbatch"

cat > "$SBATCH_FILE" << EOF
#!/bin/bash
#SBATCH --exclude=or-condo-c67
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

rm -rf ${OUT_DIR}/*
rm -rf work/

export NXF_OPTS="-Xms10g -Xmx10g"

nextflow -C nextflow.config run main.nf \
    --raw_file "$RAW" \
    --outdir "$OUT_DIR" \
    --container "$CONTAINER" \
    -with-singularity "$CONTAINER" \
    -resume \
    -with-timeline ${OUT_DIR}/timeline.html \
    -with-dag ${OUT_DIR}/flowchart.html \
    -with-report ${OUT_DIR}/report.html \
    -with-trace

mv trace* ${OUT_DIR}/
EOF

    echo "Submitting: $SBATCH_FILE"
    sbatch "$SBATCH_FILE"

done

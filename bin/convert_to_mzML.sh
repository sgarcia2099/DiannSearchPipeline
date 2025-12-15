#!/usr/bin/env bash
set -euo pipefail

# Input RAW file
RAWFILE="$1"

# Check that the input file exists
if [[ ! -f "$RAWFILE" ]]; then
    echo "ERROR: Input file not found: $RAWFILE" >&2
    exit 1
fi

# Define output directory and file
OUTDIR=$(dirname "$RAWFILE")
OUTFILE="${RAWFILE%.raw}.mzML"

echo "[INFO] Converting raw file: $RAWFILE"
echo "[INFO] Output directory:   $OUTDIR"
echo "[INFO] Output file:        $OUTFILE"

# Singularity container image path
CONTAINER_IMAGE="/lustre/or-scratch/cades-bsd/$USER/singularity_cache/quay.io-biocontainers-thermorawfileparser:1.4.5--h05cac1d_1.img"

# Check if the container image exists
if [[ ! -f "$CONTAINER_IMAGE" ]]; then
    echo "ERROR: Singularity image not found: $CONTAINER_IMAGE" >&2
    exit 1
fi

# Bind necessary paths and execute the parser inside the container
singularity exec \
    --bind /lustre:/lustre \
    "$CONTAINER_IMAGE" \
    ThermoRawFileParser \
        -i "$RAWFILE" \
        -o "$OUTDIR" \
        -f 1 \
        --gzip

if [[ -f "$OUTFILE" ]]; then
    echo "[INFO] Conversion successful. Output file: $OUTFILE"
else
    echo "ERROR: Conversion failed. Output file was not created." >&2
    exit 1
fi
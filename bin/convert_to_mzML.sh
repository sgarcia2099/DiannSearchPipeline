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

ThermoRawFileParser \
    -i "$RAWFILE" \
    -o "$OUTDIR" \
    -f 1 \

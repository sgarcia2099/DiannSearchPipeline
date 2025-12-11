#!/usr/bin/env bash
set -euo pipefail

RAWFILE="$1"

if [[ ! -f "$RAWFILE" ]]; then
    echo "ERROR: Input file not found: $RAWFILE" >&2
    exit 1
fi

OUTFILE="${RAWFILE%.raw}.mzML"

echo "[INFO] Converting: $RAWFILE"
echo "[INFO] Output:     $OUTFILE"

# ThermoRawFileParser available inside container
ThermoRawFileParser \
    -i "$RAWFILE" \
    -o "$OUTFILE" \
    -f 2

echo "[INFO] Done."

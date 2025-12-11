#!/usr/bin/env bash
set -e

# ------------------------------
# Minimal input parser
# ------------------------------
INPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            INPUT="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 -i <input.raw>"
            exit 1
            ;;
    esac
done

if [[ -z "$INPUT" ]]; then
    echo "[ERROR] Input file required"
    exit 1
fi

# ------------------------------
# Generate output filename
# ------------------------------
OUTPUT="${INPUT%.raw}.mzML"
echo "[INFO] Converting $INPUT → $OUTPUT"

# ------------------------------
# Linux ThermoRawFileParser path inside container
# ------------------------------
TRFP_DIR="/opt/ThermoRawFileParser"  # adjust to container path

# ------------------------------
# Run conversion
# ------------------------------
"$TRFP_DIR/ThermoRawFileParser" -i "$INPUT" -b "$OUTPUT" -f 1

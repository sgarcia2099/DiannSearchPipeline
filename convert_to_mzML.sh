#!/usr/bin/env bash
set -e

# Parse input arguments
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
    echo "Error: input file required"
    exit 1
fi

# Auto-generate output file in the same folder
OUTPUT="${INPUT%.raw}.mzML"

echo "[INFO] Converting $INPUT → $OUTPUT"

# Path to Linux ThermoRawFileParser
TRFP_DIR="$HOME/ThermoRawFileParser"

# Run conversion
"$TRFP_DIR/ThermoRawFileParser" -i "$INPUT" -b "$OUTPUT" -f 1

#!/usr/bin/env bash
set -e

INPUT="$1"
OUTPUT="$(dirname "$INPUT")/$(basename "$INPUT" .raw).mzML"
TRFP_DIR="$HOME/ThermoRawFileParser"  # path to Linux binary

# Run native Linux ThermoRawFileParser
"$TRFP_DIR/ThermoRawFileParser" -i "$INPUT" -b "$OUTPUT" -f 1

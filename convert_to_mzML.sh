#!/usr/bin/env bash

set -e
# 'set -e' makes the script exit immediately if ANY command fails.
# This is important in Nextflow so the pipeline stops on errors
# instead of silently continuing with bad output.

###############################################
# INITIAL VARIABLES
###############################################

INPUT=""
OUTPUT=""

# Set the directory where ThermoRawFileParser is located.
# This keeps the script usable in:
#   - your local shell   (HOME is valid)
#   - Nextflow jobs      (HOME is inherited)
TRFP_DIR="$HOME/ThermoRawFileParser"

###############################################
# FLAG PARSER (MINIMAL)
###############################################
# This loop scans all command-line arguments.
# It supports -i and -o in ANY order:
#
#   ./trfp.sh -i file.raw -o file.mzML
#   ./trfp.sh -o out.mzML -i in.raw
#   ./trfp.sh something -i in.raw -o out.mzML
#
# No validation logic — bare-bones as requested.

while [[ $# -gt 0 ]]; do
    case "$1" in

        -i)
            INPUT="$2"   # save the input file path
            shift 2      # skip over -i and its value
            ;;

        -o)
            OUTPUT="$2"  # save the output file path
            shift 2      # skip over -o and its value
            ;;

        *)
            shift        # ignore anything else
            ;;
    esac
done


###############################################
# EXECUTE THERMORAWFILEPARSER
###############################################

# Move into the tool directory.
# Nextflow will run this script inside its own work folder,
# so using an absolute path ensures the tool is found reliably.
cd "$TRFP_DIR"

# Run the converter.
# -f 1 selects mzML output.
./ThermoRawFileParser \
    -i "$INPUT" \
    -o "$OUTPUT" \
    -f 1


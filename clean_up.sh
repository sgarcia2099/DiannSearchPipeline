#!/bin/bash
# Archive old job directories and prepare for new pipeline run

set -e

BASE_DIR="/lustre/or-scratch/cades-bsd/jkg"
cd "$BASE_DIR"

echo "===== Archiving previous job directories ====="

# Find all job directories
JOB_DIRS=$(find . -maxdepth 1 -type d -name "diann_job_*" 2>/dev/null | sort)

if [ -z "$JOB_DIRS" ]; then
    echo "No previous job directories found to archive."
else
    # Archive each job directory separately
    for JOB_DIR in $JOB_DIRS; do
        JOB_NAME=$(basename "$JOB_DIR")
        ARCHIVE_NAME="${JOB_NAME}.tar.gz"

        echo "Removing raw files before archiving to save space..."
        find "$JOB_DIR" -type f -name "*.raw" -print -delete
        
        echo "Archiving: $JOB_NAME -> $HOME/$ARCHIVE_NAME"
        tar -czf "$HOME/$ARCHIVE_NAME" "$JOB_NAME"
        
        # Remove the archived job directory
        rm -rf "$JOB_DIR"
        echo "  Archived and removed: $JOB_DIR"
    done
    
    echo ""
    echo "All job directories archived to $HOME/"
fi

echo ""
echo "===== Cleaning up temporary directories ====="
# Clean up shared temporary directories (but keep cache for container reuse)
if [ -d "tmp" ]; then 
    rm -rf tmp
    echo "Removed tmp/"
fi

echo ""
echo "===== Preparing staging area for new job ====="
# Ensure staging directories exist
mkdir -p "$BASE_DIR/rawfiles"
mkdir -p "$BASE_DIR/fasta"
mkdir -p "$BASE_DIR/configs"

echo ""
echo "===== Current staging area status ====="
echo "Place your files here before running submit_diann.sh:"
echo "  - Raw files: $BASE_DIR/rawfiles/"
echo "  - FASTA files: $BASE_DIR/fasta/"
echo "  - Config files: $BASE_DIR/configs/"
echo ""
echo "Note: Container cache preserved at $BASE_DIR/cache/ for reuse"
echo ""
echo "Cleanup complete!"
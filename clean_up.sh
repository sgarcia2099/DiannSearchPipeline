#!/bin/bash
# Move pipeline-generated archives to home and clean up job directories

set -e

BASE_DIR="/lustre/or-scratch/cades-bsd/jkg"
cd "$BASE_DIR"

echo "===== Processing completed job directories ====="

# Find all job directories
JOB_DIRS=$(find . -maxdepth 1 -type d -name "diann_job_*" 2>/dev/null | sort)

# Get active SLURM job names to avoid processing running jobs
ACTIVE_JOBS=$(squeue -h -u "$USER" -o "%j" 2>/dev/null || true)

if [ -z "$JOB_DIRS" ]; then
    echo "No job directories found."
else
    # Process each job directory separately
    for JOB_DIR in $JOB_DIRS; do
        JOB_NAME=$(basename "$JOB_DIR")

        # Derive timestamp and related SLURM job names
        JOB_TS="${JOB_NAME#diann_job_}"
        PREP_JOB_NAME="diann_prep_${JOB_TS}"
        MAIN_JOB_NAME="diann_${JOB_TS}"

        # Skip if job is still active in SLURM
        if echo "$ACTIVE_JOBS" | grep -Fxq "$PREP_JOB_NAME" || echo "$ACTIVE_JOBS" | grep -Fxq "$MAIN_JOB_NAME"; then
            echo "Skipping active job directory: $JOB_NAME (job still running)"
            continue
        fi

        # Look for pipeline-generated archive in results directory
        RESULTS_DIR="$JOB_DIR/results"
        ARCHIVE_FILE=$(find "$RESULTS_DIR" -maxdepth 1 -type f -name "diann_results_*.tar.gz" 2>/dev/null | head -n 1)

        if [ -n "$ARCHIVE_FILE" ]; then
            ARCHIVE_NAME=$(basename "$ARCHIVE_FILE")
            echo "Moving archive: $ARCHIVE_NAME -> $HOME/"
            mv "$ARCHIVE_FILE" "$HOME/"
            echo "  Moved: $ARCHIVE_FILE"
            
            # Remove the job directory after moving archive
            echo "Removing job directory: $JOB_DIR"
            rm -rf "$JOB_DIR"
            echo "  Cleaned up: $JOB_DIR"
        else
            echo "No archive found for $JOB_NAME (may still be processing or failed)"
        fi
    done
    
    echo ""
    echo "All completed job archives moved to $HOME/"
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
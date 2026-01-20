# DiannSearchPipeline

Pipeline for searching Thermo `.raw` files using [DIA-NN](https://github.com/vdemichev/DiaNN).

- Directories are hardcoded for user `jkg` at `/lustre/or-scratch/cades-bsd/jkg`
- Pipeline built using Nextflow and SLURM job handling
- Pipeline was constructed using DIA-NN 2.3.1 - Academia for Linux
- Each job submission creates an isolated job directory with all files copied

---

### Quick Start

1. Place your files in the staging area:
   - `.raw` files → `/lustre/or-scratch/cades-bsd/jkg/rawfiles/`
   - `.fasta` files → `/lustre/or-scratch/cades-bsd/jkg/fasta/`
   - `.cfg` config files → `/lustre/or-scratch/cades-bsd/jkg/configs/`

2. Submit the pipeline:
   ```bash
   cd ~/github/DiannSearchPipeline
   ./submit_diann.sh 2.3.1
   ```

3. The job will run in an isolated directory (e.g., `diann_job_20260120_143022/`) with outputs in:
   ```
   /lustre/or-scratch/cades-bsd/jkg/diann_job_YYYYMMDD_HHMMSS/results/
   ```

---

### Containers

**DIA-NN**: [garciasarah2099/diannpipeline](https://hub.docker.com/r/garciasarah2099/diannpipeline)

--- Multi-Job Workflow Guide

## Overview
This pipeline now supports submitting multiple independent DIA-NN jobs by using unique job directories. Each job is self-contained with its own copies of all necessary files.

## Key Features

1. **Container Reuse**: The Apptainer container is pulled once and stored as a `.sif` file in the shared cache directory. All subsequent jobs reuse this container.

2. **Self-Contained Jobs**: Each job submission creates a unique timestamped directory (`diann_job_YYYYMMDD_HHMMSS`) containing:
   - All input files (rawfiles, fasta, configs)
   - Pipeline files (main.nf, nextflow.config)
   - Job-specific outputs (results/, work/, logs/)

3. **Independent Archiving**: The cleanup script archives each job directory separately, preserving the complete state of each run.

## Workflow Steps

### 1. Initial Setup (One Time)
First time only - ensure your base directories exist:
```bash
BASE="/lustre/or-scratch/cades-bsd/jkg"
mkdir -p $BASE/rawfiles
mkdir -p $BASE/fasta
mkdir -p $BASE/configs
```

### 2. Prepare Files for a Job
Place your files in the staging area:
```bash
BASE="/lustre/or-scratch/cades-bsd/jkg"

# Copy your raw files
cp /path/to/your/*.raw $BASE/rawfiles/

# Copy/update your FASTA files
cp /path/to/your/*.fasta $BASE/fasta/

# Copy/update your config files
cp /path/to/your/configs/*.cfg $BASE/configs/
```

### 3. Submit the Job
```bash
cd ~/github/DiannSearchPipeline
./submit_diann.sh 2.3.1
```

This will:
- Pull the container if not already cached (first run only)
- Create a unique job directory (e.g., `diann_job_20260120_143022`)
- Copy all necessary files into the job directory
- Submit the SLURM job

### 4. Submit Additional Jobs
To run another job with different data:

```bash
# Clear the staging area
rm -rf $BASE/rawfiles/*
rm -rf $BASE/fasta/*

# Add new files
cp /path/to/new/*.raw $BASE/rawfiles/
cp /path/to/new/*.fasta $BASE/fasta/

# Submit the new job
./submit_diann.sh 2.3.1
```

The second job will:
- Reuse the cached container (no re-download)
- Create a new unique job directory
- Run independently without affecting the first job

### 5. Monitor Jobs
Each job directory contains its own logs:
```bash
# Find your job directories
ls -ld /lustre/or-scratch/cades-bsd/jkg/diann_job_*

# Check logs for a specific job
tail -f /lustre/or-scratch/cades-bsd/jkg/diann_job_20260120_143022/logs/nf_*.out
```

### 6. Cleanup and Archive Old Jobs
When you want to clean up old completed jobs:
```bash
cd ~/github/DiannSearchPipeline
./clean_up.sh
```

This will:
- Archive each job directory separately to `$HOME/diann_job_YYYYMMDD_HHMMSS.tar.gz`
- Remove the archived job directories
- Preserve the container cache for future use
- Ensure staging directories are ready for the next job

## Directory Structure

```
/lustre/or-scratch/cades-bsd/jkg/
├── cache/                          # Shared container storage
│   └── diannpipeline_2.3.1.sif   # Reusable container
├── tmp/                            # Shared temporary files
├── rawfiles/                       # Staging area for raw files
├── fasta/                          # Staging area for FASTA files
├── configs/                        # Staging area for config files
├── diann_job_20260120_143022/     # Job 1 (independent)
│   ├── rawfiles/
│   ├── fasta/
│   ├── configs/
│   ├── results/
│   ├── work/
│   ├── logs/
│   ├── main.nf
│   └── nextflow.config
└── diann_job_20260120_145530/     # Job 2 (independent)
    ├── rawfiles/
    ├── fasta/
    ├── configs/
    ├── results/
    ├── work/
    ├── logs/
    ├── main.nf
    └── nextflow.config
```

## Benefits

- **Complete Isolation**: Each job has its own copies of all input files - changes to staging areas won't affect running jobs
- **No Conflicts**: Multiple jobs can run simultaneously without interfering with each other
- **Complete Records**: Each job directory preserves the exact inputs and outputs used
- **Easy Cleanup**: Archive and remove old jobs without losing data
- **Fast Submission**: Container is pulled once and reused for all subsequent jobs
- **Reproducibility**: Each archived job contains everything needed to understand that specific run

## Important Notes

- **User-specific**: Pipeline is configured for user `jkg` (paths hardcoded)
- **Container binary path**: Uses `/diann-${params.diann_version}/diann-linux` inside containers
- **Isolation**: Apptainer bindpath is restricted to job directory only - staging areas are NOT accessible to running jobs
- **File staging**: All input files are deep-copied at submission time, ensuring complete independence

## Tips

- Don't modify staging area files while jobs are copying (wait for "Job submitted successfully!" message)
- Monitor disk space - each job creates its own copy of input files
- Archive and remove old jobs regularly to free up space
- Container cache is shared at `/lustre/or-scratch/cades-bsd/jkg/cache/` for all jobs

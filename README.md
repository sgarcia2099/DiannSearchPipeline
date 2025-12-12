# DiannSearchPipeline

A scalable Nextflow workflow that converts Thermo `.raw` files into `.mzML` files using **ThermoRawFileParser** inside an **Apptainer/Singularity** container. Designed for cloud/HPC environments using **Slurm**.

---

## Features
- Parallel conversion of `.raw` files to `.mzML`
- Fully reproducible with Apptainer/Singularity
- Optimized for Slurm HPC environments
- Work directories default to `/lustre/or-scratch/cades-bsd/$USER`

---

## Quick Start Guide

### Repository Structure

```
DiannSearchPipeline/
├── [main.nf](main.nf)                # Workflow definition
├── [nextflow.config](nextflow.config) # Slurm + container config
├── [bin/](bin/)                      # Additional scripts
│   └── [convert_to_mzML.sh](bin/convert_to_mzML.sh) # Wrapper script
└── [containers/](containers/)        
    └── TRFP.sif                      # Place your container here  
```

---

### Preparing the Container

**Option 1**: Build from a Docker image:
```bash
apptainer build containers/TRFP.sif docker://<your-docker-image>
```

**Option 2**: Use an existing `.sif` file by placing it in `containers/`.

---

### Running the Pipeline

1. Place `.raw` files in `/lustre/or-scratch/cades-bsd/$USER/rawfiles` (recommended for large datasets):
   ```bash
   mkdir -p /lustre/or-scratch/cades-bsd/$USER/rawfiles && cp *.raw /lustre/or-scratch/cades-bsd/$USER/rawfiles/
   ```

2. Run the pipeline:
   ```bash
   nextflow run main.nf \
       --rawDir /lustre/or-scratch/cades-bsd/$USER/rawfiles \
       --outDir /lustre/or-scratch/cades-bsd/$USER/mzml_output \
       -with-singularity containers/TRFP.sif
   ```

3. Outputs are written to:
   ```
   /lustre/or-scratch/cades-bsd/$USER/mzml_output/
   ```

---

### Debugging Slurm Jobs

- **Resuming Failed Runs:**
  ```bash
  nextflow run main.nf -resume
  ```

- **Inspecting Failed Jobs:**
  ```bash
  cd work/<hash>/
  cat .command.err
  ```

---

## Summary Table

| File/Location                | Purpose                                  |
|------------------------------|------------------------------------------|
| [`main.nf`](main.nf)         | Defines workflow steps and logic         |
| [`nextflow.config`](nextflow.config) | Sets Slurm execution parameters            |
| [`bin/convert_to_mzML.sh`](bin/convert_to_mzML.sh) | Wrapper script for the container         |
| [`containers/TRFP.sif`](containers/) | Apptainer container with ThermoRawFileParser |
| `/lustre/or-scratch/cades-bsd/$USER/rawfiles`                   | Recommended storage for raw data         |

---

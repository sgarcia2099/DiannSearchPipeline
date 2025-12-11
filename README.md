# DiannSearchPipeline

A scalable Nextflow workflow that converts Thermo `.raw` files into `.mzML` files using **ThermoRawFileParser** inside an **Apptainer/Singularity** container. Designed for cloud/HPC environments using **Slurm**.

---

## Features
- Parallel conversion of `.raw` files to `.mzML`
- Fully reproducible with Apptainer/Singularity
- Optimized for Slurm HPC environments
- Work directories default to `/scratch/$USER`

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

1. Place `.raw` files in `/scratch` (recommended for large datasets):
   ```bash
   mkdir -p /scratch/$USER/rawfiles && cp *.raw /scratch/$USER/rawfiles/
   ```

2. Run the pipeline:
   ```bash
   nextflow run main.nf \
       --rawDir /scratch/$USER/rawfiles \
       --outDir /scratch/$USER/mzml_output \
       -with-singularity containers/TRFP.sif
   ```

3. Outputs are written to:
   ```
   /scratch/$USER/mzml_output/
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
| `/scratch`                   | Recommended storage for raw data         |

---

## License

MIT
# DiannSearchPipeline

A scalable Nextflow workflow that converts Thermo `.raw` files into `.mzML` files using **ThermoRawFileParser** inside an **Apptainer/Singularity** container. Designed for cloud/HPC environments using **Slurm**.

---

## Features
- Parallel conversion of `.raw` files to `.mzML`
- Work directories default to `/lustre/or-scratch/cades-bsd/$USER`

---

### Running the Pipeline

1. Place `.raw` files in `/lustre/or-scratch/cades-bsd/$USER/rawfiles`:

2. Run the pipeline:
   ```bash
   ./submit_diann.sh
   ```

3. Outputs are written to:
   ```
   /lustre/or-scratch/cades-bsd/$USER/results/
   ```

---
### Container

Using the **ThermoRawFileParser** container from [biocontainers/thermorawfileparser/tags](https://quay.io/repository/biocontainers/thermorawfileparser?tab=tags).

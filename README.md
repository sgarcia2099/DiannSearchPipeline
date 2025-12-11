Here is the full README for the repo:

# DiannSearchPipeline

A scalable Nextflow workflow that converts Thermo `.raw` files into `.mzML` files using **ThermoRawFileParser** inside an **Apptainer/Singularity** container.

Designed for cloud/HPC environments using **Slurm**.

---

## Features
- Runs 100s of `.raw` conversions in parallel
- Uses Apptainer/Singularity for fully reproducible execution
- Tested on cloud HPC with Slurm
- Work directories automatically placed in `/scratch/$USER`
- Lightweight script in `bin/` automatically added to `$PATH`

---

## Repository Structure

DiannSearchPipeline/
├── main.nf
├── nextflow.config
├── README.md
├── bin/
│ └── convert_to_mzML.sh
└── containers/
└── TRFP.sif # Place your container here


---

## Preparing the Container

If you have a Docker image:

```bash
apptainer build containers/TRFP.sif docker://your-docker-image-here
```

OR if you already have a .sif file, drop it in containers/.

## Running the Pipeline

Place your .raw files in a large fast storage directory like /scratch:

/scratch/$USER/rawfiles/*.raw

Run the pipeline:
```bash
nextflow run main.nf \
    --rawDir /scratch/$USER/rawfiles \
    --outDir /scratch/$USER/mzml_output \
    -with-singularity containers/TRFP.sif
```

Outputs will be written to:

/scratch/$USER/mzml_output/

Slurm Behavior

Each .raw file becomes a separate Slurm job.

Resources are assigned via:

label 'med'


You can adjust these in nextflow.config.

Debugging

To resume a failed run:

nextflow run main.nf -resume


To inspect a failed job:

cd work/<hash>/
cat .command.err

License

MIT


---

## Summary

| Component | Purpose |
|----------|---------|
| `DiannSearchPipeline` | GitHub repo you clone to your HPC |
| `bin/convert_to_mzML.sh` | Simple wrapper script that runs inside the container |
| `main.nf` | Defines workflow steps + process logic |
| `nextflow.config` | Slurm execution, container configuration, scratch dir |
| `containers/TRFP.sif` | Apptainer container with ThermoRawFileParser |
| `/scratch` | Where large raw data lives (not in home dir) |

---

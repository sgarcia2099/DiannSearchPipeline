# DiannSearchPipeline

Pipeline for searching Thermo `.raw` files using [DIA-NN](https://github.com/vdemichev/DiaNN).

- Directories default to `/lustre/or-scratch/cades-bsd/$USER`
- Pipeline built using Nextflow and SLURM job handling
- Pipeline was constructed using DIA-NN 2.3.1 - Academia for Linux

---

### Running the Pipeline

1. Place `.raw` files in `/lustre/or-scratch/cades-bsd/$USER/rawfiles`
2. Place `.fasta` files in `/lustre/or-scratch/cades-bsd/$USER/fasta`
3. Place `.cfg` files (for DIA-NN) in `/lustre/or-scratch/cades-bsd/$USER/configs`

4. Run the pipeline:
   ```bash
   ./submit_diann.sh <diann-version>
   ```

5. Outputs are written to:
   ```
   /lustre/or-scratch/cades-bsd/$USER/results/
   ```

---

### Containers

**Dia-NN**: [garciasarah2099/diannpipeline](https://hub.docker.com/r/garciasarah2099/diannpipeline)

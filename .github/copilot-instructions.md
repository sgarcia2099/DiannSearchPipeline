# Copilot instructions — DiannSearchPipeline

Purpose
- Brief: This repository is a Nextflow-based DIA proteomics pipeline (DIANN) tuned for SLURM + Apptainer environments.

Big picture (what to know first)
- Core runner: Nextflow pipeline (entry typically `main.nf`) using `nextflow.config` for cluster/container settings.
- Execution environment: SLURM executor with Apptainer containers (see [nextflow.config](nextflow.config)).
- Data flow: raw files → Nextflow channels → process tasks (labeled `small` or `large`) → outputs under `params.outdir` and the Nextflow `work` directory.

Key files to inspect
- `nextflow.config`: cluster, container image, resource labels, and important `params.*` (raw_dir, fasta_dir, config_dir, outdir, workDir).
- `main.nf` (pipeline logic) and any `modules/` or `workflow/` subfiles — these contain the process definitions and channels.

Concrete process map (from `main.nf`)
- `generate_library`:
  - label: `large`
  - inputs: `fasta_dir`, `config_dir` (channels created from `params.fasta_dir`, `params.config_dir`).
  - outputs: `results/report-lib.predicted.speclib` (emitted as `spectral_library`).
  - command: runs `/diann-${params.diann_version}/diann-linux --cfg ${config_dir}/diann_speclib_config.cfg` inside the container environment.

- `diann_search`:
  - label: `large`
  - inputs: `raw_dir`, `fasta_dir`, `config_dir`, and the `spectral_library` emitted by `generate_library`.
  - outputs: all matching files (`path "*.*"`) into `results/`.
  - command: runs `/diann-${params.diann_version}/diann-linux --cfg ${config_dir}/diann_search_config.cfg`.

Notes about `params.diann_version`
- The pipeline expects the container or image to expose a path like `/diann-<version>/diann-linux`. Ensure the Apptainer image labeled by `params.diann_version` contains that binary at runtime, or adjust the script lines in `main.nf` accordingly.

DIANN Config Summary
- **Version**: 2.3.1 (both example configs use DIA-NN 2.3.1)
- **Config files**: `configs/diann_speclib_config.cfg` (library generation) and `configs/diann_search_config.cfg` (search)
- **Key fasta inputs**: `fasta/SG_all_combined_20250610.fasta` and `fasta/contams.fasta` (both configs reference these)
- **Spectral library outputs**: speclib generation writes `result.predicted.speclib` (and `report-lib.parquet` as the lib report). The search config expects the library at `results/result.predicted.speclib` in the example pipeline.
- **Search outputs**: example search writes `report.parquet` (main search report) and exports matrices when `--matrices` is set.
- **Common runtime flags**: `--threads 20`, `--verbose 1`, `--qvalue 0.01`, `--matrices`, `--export-quant`, `--report-file-name`.
- **Peptide / mass filters**: `--min-pep-len 6`, `--max-pep-len 30`, `--min-pr-mz 300`, `--max-pr-mz 1800`, `--min-fr-mz 200`, `--max-fr-mz 1800`, `--min-pr-charge 1`, `--max-pr-charge 4`.
- **Digestion / mods**: `--cut K*,R*`, `--missed-cleavages 2`, `--unimod4` (fixed Cys carbamidomethylation), `--var-mods 3`, `--var-mod UniMod:35,15.994915,M`, `--met-excision`.
- **Mass accuracy / windows**: `--mass-acc 20`, `--mass-acc-ms1 15`, `--individual-mass-acc`, `--individual-windows`, `--window 10`.
- **Library generation / profiling**: `--gen-spec-lib`, `--predictor`, `--fasta-search`, `--rt-profiling` (used for empirical library generation).
- **Inference / advanced**: `--proteoforms`, `--pg-level 2` (gene-level grouping), `--species-genes`, `--species-ids`.

Notes
- Ensure the `--lib` path used in `configs/diann_search_config.cfg` matches the spectral library emitted by the library generation step (pipeline currently expects a `results/`-scoped library path).
- The example configs use 20 threads; align `submit_diann.sh` SBATCH `-c` and Nextflow `withLabel` settings if you adjust thread counts.
- If you change `params.diann_version`, verify the container image exposes `/diann-<version>/diann-linux` or update `main.nf` to point to the actual binary path inside your image.

Helpful repo artifacts
- `submit_diann.sh`: convenience script that invokes `nextflow run main.nf` — useful as an example invocation or for cluster submission wrappers.

Exact cluster submission flow (from `submit_diann.sh`)
- Purpose: `submit_diann.sh <DIANN_VERSION>` builds an SBATCH wrapper that sets environment vars, binds the workspace paths, and submits a SLURM job which runs Nextflow.
- Key exported env vars set before running:
  - `APPTAINER_TMPDIR` -> e.g. `/lustre/or-scratch/cades-bsd/$USER/tmp`
  - `APPTAINER_CACHEDIR` -> e.g. `/lustre/or-scratch/cades-bsd/$USER/cache`
  - `APPTAINER_BINDPATH` -> e.g. `/lustre/or-scratch/cades-bsd/$USER`
- The generated SBATCH runs the pipeline with these exact flags:

```bash
nextflow run main.nf \
    --raw_dir "$BASE/rawfiles" \
    --outdir "$BASE/results" \
    --diann_version "$DIANN_VERSION" \
    -resume
```

Notes for agents
- The script validates there are `.raw` files in `$BASE/rawfiles` and creates necessary `logs/` and `results/` directories — match those conventions when writing tests or docs.
- SBATCH resource hints: `-c 32`, `--mem=125g`, `--nodes=1`, `-t 1-00:00:00` — processes still use `withLabel` resource settings, but the submission wrapper requests a large SLURM allocation.
- When suggesting changes to execution flags, prefer modifying `submit_diann.sh` or adding a new `profile` in `nextflow.config` to keep user workflow consistent.

Project-specific conventions
- Resource labels: use `withLabel: small` and `withLabel: large` in `nextflow.config`. Processes should pick one of these labels to inherit resource settings.
- Containerization: `container = "garciasarah2099/diannpipeline:${params.diann_version}"` — do not hardcode image tags; prefer using `--diann_version` or `params.diann_version` when running.
- Filesystem: paths in `nextflow.config` point to a shared Lustre-like filesystem (`/lustre/...`). Avoid changing to local paths when targeting cluster runs; use parameters instead.
- Apptainer specifics: `apptainer.enabled = true` and a `cacheDir` are configured. Agents should assume builds/run use Apptainer rather than Docker unless directed otherwise.

Run / debug workflows (concrete commands)
- Run pipeline (produce logs & reports):

```bash
nextflow run . -c nextflow.config \
  -with-trace logs/trace.txt \
  -with-report logs/report.html \
  -with-timeline logs/timeline.html \
  -with-dag logs/dag.html \
  --diann_version 1.0.0
```

- Re-run after fixing: add `-resume` to reuse completed process outputs.
- Debug single processes: locate the failing process in `work/` (Nextflow work dir), inspect its `command.sh` and `.command.err` / `.command.log` output. Use Nextflow's trace/report HTML files for quick failure summaries.

Testing & CI expectations
- There is no repository-level test harness discovered; prefer small local smoke runs with a minimal subset of inputs and `-process` labels tuned to `small` to validate changes.

Integration points & external dependencies
- SLURM — configured via `process.executor = 'slurm'` and `clusterOptions` in `nextflow.config`.
- Apptainer (Singularity) — container runtime and image cache used for reproducible environments.
- Container registry — images referenced by `garciasarah2099/diannpipeline` (pull/push credentials may be required).

What agents should avoid changing
- Do not replace cluster-specific paths in `nextflow.config` with local absolute paths. Instead, make changes parameterized via `params.*`.
- Do not hardcode container tags; use `params.diann_version`.

Examples of helpful edits an agent can make
- Add a `profiles` section to `nextflow.config` for `local` vs `cluster` runs, exposing `params` overrides.
- Add a small `test-data/` folder and an example command in README showing a minimal smoke test invocation.

If something is unclear
- Point to the specific file or process name (e.g., the process in `main.nf` that joins channels A and B) and request sample inputs or desired outputs.

---
If you'd like, I can: (1) look for `main.nf` and modules to extract concrete process names, (2) add a `profiles` example, or (3) create a short README example for running locally.

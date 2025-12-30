#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Default DIA-NN version
params.diann_version = params.diann_version ?: '2.3.1'

// Input channel
Channel
    .fromPath("${params.raw_dir}/*.raw", checkIfExists: true)
    .set { raw_files }

Channel
    .fromPath(params.fasta)

// Generate Spectral Library
process generate_library {
    
    label 'large'
    publishDir params.outdir, mode: 'copy'

    input:
        path fasta_files

    output:
        path "*.predicted.speclib" into generated_library

    script:
    """
    echo "Generating spectral library..."

    cp ${params.outdir}/library_${SLURM_JOB_ID}.predicted.speclib .
    """

}

// Run DIA-NN search
process diann_search {

    label 'large'
    publishDir params.outdir, mode: 'copy'

    input:
        path raw_files
        path diann_config
        path spectral_library from generated_library.collect()

    output:
        path "*.tsv"

    script:
    """
    echo "Found \$(ls *.raw | wc -l) RAW files"
    echo "Using spectral library: \$(ls *.predicted.speclib)"

    CONFIG_COPY="diann_config_${SLURM_JOB_ID}.cfg"
    cp ${diann_config} \$CONFIG_COPY

    # Replace placeholders
    sed -i "s|\\\${RAW_DIR}|.|g" \$CONFIG_COPY
    sed -i "s|\\\${LIBRARY}|\$(ls *.tsv)|g" \$CONFIG_COPY
    sed -i "s|\\\${FASTA}|${params.fasta}|g" \$CONFIG_COPY
    sed -i "s|\\\${OUTDIR}|${params.outdir}|g" \$CONFIG_COPY

    # Append all RAW files as --f entries
    for f in *.raw; do
        echo "--f \$f" >> \$CONFIG_COPY
    done

    echo "Using config file:"
    cat \$CONFIG_COPY

    # Run DIA-NN search
    DIA-NN --conf \$CONFIG_COPY --out results_\${SLURM_JOB_ID}.tsv
    """
}

// Workflow
workflow {
    def config_file = file("diann_config.cfg")
    diann_search(raw_files.collect(), config_file)
}

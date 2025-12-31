#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Default DIA-NN version
params.diann_version = params.diann_version ?: '2.3.1'

// Input channels
Channel.fromPath("${params.raw_dir}/*.raw", checkIfExists: true).collect().set { raw_files }
Channel.of(file(params.fasta)).set { fasta_main }
Channel.of(file(params.fastaContam)).set { fasta_contam }

// Generate Spectral Library
process generate_library {

    label 'large'
    publishDir params.outdir, mode: 'copy'

    input:
        path fasta_main
        path fasta_contam
        path speclib_config_file

    output:
        path "*.predicted.speclib", emit: generated_library

    script:
    """
    echo "Generating spectral library..."
    echo "FASTA: ${fasta_main}"
    echo "CONTAM: ${fasta_contam}"

    CONFIG_COPY="diann_speclib_config_\${SLURM_JOB_ID}.cfg"
    echo "Config copy will be: \$CONFIG_COPY"
    cp ${speclib_config_file} \$CONFIG_COPY

    sed -i "s|\\\${FASTA}|${fasta_main}|g" \$CONFIG_COPY
    sed -i "s|\\\${FASTA_CONTAM}|${fasta_contam}|g" \$CONFIG_COPY
    sed -i "s|\\\${OUTDIR}|${params.outdir}|g" \$CONFIG_COPY

    echo "----- CONFIG COPY CONTENTS -----"
    cat \$CONFIG_COPY
    echo "--------------------------------"

    /diann-${params.diann_version}/diann-linux \
        --cfg \$CONFIG_COPY \
        --out ${params.outdir}/library_\${SLURM_JOB_ID}.predicted.speclib
    """
}

// Run DIA-NN search
process diann_search {

    label 'large'
    publishDir params.outdir, mode: 'copy'

    input:
        path raw_files
        path fasta_main
        path fasta_contam
        path search_config_file
        path spectral_library

    output:
        path "*.*"

    script:
    """
    echo "Processing \${#raw_files[@]} RAW files"
    echo "Using spectral library: ${spectral_library}"

    CONFIG_COPY="diann_config_\${SLURM_JOB_ID}.cfg"
    echo "Config copy will be: \$CONFIG_COPY"
    cp ${search_config_file} \$CONFIG_COPY

    sed -i "s|\\\${RAW_DIR}|.|g" \$CONFIG_COPY
    sed -i "s|\\\${LIBRARY}|${spectral_library}|g" \$CONFIG_COPY
    sed -i "s|\\\${FASTA}|${fasta_main}|g" \$CONFIG_COPY
    sed -i "s|\\\${FASTA_CONTAM}|${fasta_contam}|g" \$CONFIG_COPY
    sed -i "s|\\\${OUTDIR}|${params.outdir}|g" \$CONFIG_COPY

    echo "----- CONFIG COPY CONTENTS -----"
    cat \$CONFIG_COPY
    echo "--------------------------------"

    for f in ${raw_files.join(' ')}; do
        echo "--f \$f" >> \$CONFIG_COPY
    done

    /diann-${params.diann_version}/diann-linux \
        --cfg \$CONFIG_COPY \
        --out ${params.outdir}/results_\${SLURM_JOB_ID}.tsv
    """
}


// Workflow
workflow {
    def search_config_file = file("diann_config.cfg")
    def speclib_config_file = file("diann_speclib_config.cfg")

    def lib = generate_library(
        fasta_main,
        fasta_contam,
        speclib_config_file
    )

    diann_search(
        raw_files,
        fasta_main,
        fasta_contam,
        search_config_file,
        lib.generated_library
    )
}
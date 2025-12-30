#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Default DIA-NN version
params.diann_version = params.diann_version ?: '2.3.1'

// Input channel
Channel
    .fromPath("${params.raw_dir}/*.raw", checkIfExists: true)
    .set { raw_files }

Channel
    .fromPath([params.fasta, params.fastaContam], checkIfExists: true)
    .flatten()
    .set { fasta_files }

// Generate Spectral Library
process generate_library {
    
    label 'large'
    publishDir params.outdir, mode: 'copy'

    input:
        path fasta_files
        path speclib_config_file

    output:
        path "*.predicted.speclib", emit: generated_library

    script:
    """
    echo "Generating spectral library..."

    CONFIG_COPY="diann_speclib_config_${SLURM_JOB_ID}.cfg"
    cp ${speclib_config_file} \$CONFIG_COPY

    # Replace placeholders in the spectral library config file
    sed -i "s|\\\${FASTA}|${fasta_files[0]}|g" \$CONFIG_COPY
    sed -i "s|\\\${FASTA_CONTAM}|${fasta_files[1]}|g" \$CONFIG_COPY
    sed -i "s|\\\${OUTDIR}|${params.outdir}|g" \$CONFIG_COPY

    # Run DIA-NN to generate the spectral library
    diann-2.3.1/diann-linux --conf \$CONFIG_COPY --out ${params.outdir}/library_${SLURM_JOB_ID}.predicted.speclib
    """

}

// Run DIA-NN search
process diann_search {

    label 'large'
    publishDir params.outdir, mode: 'copy'

    input:
        path raw_files
        path fasta_files
        path search_config_file
        path spectral_library from generated_library

    output:
        path "*.*"

    script:
    """
    echo "Found \$(ls *.raw | wc -l) RAW files"
    echo "Using spectral library: \$(ls *.predicted.speclib)"

    CONFIG_COPY="diann_config_${SLURM_JOB_ID}.cfg"
    cp ${search_config_file} \$CONFIG_COPY

    # Replace placeholders in the search config file
    sed -i "s|\\\${RAW_DIR}|.|g" \$CONFIG_COPY
    sed -i "s|\\\${LIBRARY}|${spectral_library}|g" \$CONFIG_COPY

    # Use fasta_files directly without subshell commands
    fasta_file_1=\$(head -n 1 ${fasta_files})
    fasta_contam_file=\$(tail -n 1 ${fasta_files})

    sed -i "s|\\\${FASTA}|\${fasta_file_1}|g" \$CONFIG_COPY
    sed -i "s|\\\${FASTA_CONTAM}|\${fasta_contam_file}|g" \$CONFIG_COPY
    sed -i "s|\\\${OUTDIR}|${params.outdir}|g" \$CONFIG_COPY

    # Append all RAW files as --f entries
    for f in *.raw; do
        echo "--f \$f" >> \$CONFIG_COPY
    done

    echo "Using config file:"
    cat \$CONFIG_COPY

    # Run DIA-NN search
    diann-2.3.1/diann-linux --conf \$CONFIG_COPY --out results_\${SLURM_JOB_ID}.tsv
    """
}

// Workflow
workflow {
    def search_config_file = file("diann_config.cfg")
    def speclib_config_file = file("diann_speclib_config.cfg")

    generate_library(
        fasta_files,
        speclib_config_file
    )

    diann_search(
        raw_files.collect(),
        fasta_files,
        search_config_file,
        generate_library.out.generated_library
    )
}
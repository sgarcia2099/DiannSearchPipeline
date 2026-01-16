#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Input channels
raw_dir    = Channel.value( file(params.raw_dir) )
fasta_dir  = Channel.value( file(params.fasta_dir) )
config_dir = Channel.value( file(params.config_dir) )

// Generate spectral library
process generate_library {

    label 'large'

    input:
        path fasta_dir
        path config_dir

    output:
        path "report-lib.predicted.speclib", emit: spectral_library

    script:
    """
    mkdir -p results

    /diann-${params.diann_version}/diann-linux \
        --cfg ${config_dir}/diann_speclib_config.cfg
    """
}

// Run DIA-NN search
process diann_search {

    label 'large'

    input:
        path raw_dir
        path fasta_dir
        path config_dir
        path spectral_library

    output:
        path "*.*"

    script:
    """
    mkdir -p results

    /diann-${params.diann_version}/diann-linux \
        --cfg ${config_dir}/diann_search_config.cfg \
        --dir ${raw_dir} \
        --lib ${spectral_library}
    """
}

// Workflow
workflow {

    lib = generate_library(
        fasta_dir,
        config_dir
    )

    diann_search(
        raw_dir,
        fasta_dir,
        config_dir,
        lib
    )
}
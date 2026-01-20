#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Input channels
raw_dir    = Channel.value( file(params.raw_dir) )
fasta_dir  = Channel.value( file(params.fasta_dir) )
config_dir = Channel.value( file(params.config_dir) )

// Generate spectral library
process generate_library {

    label 'large'
    
    publishDir "${params.outdir}", mode: 'copy', pattern: "*.predicted.speclib"
    publishDir "${params.outdir}", mode: 'copy', pattern: "report-lib.*"

    input:
        path fasta_dir
        path config_dir

    output:
        path "report-lib.predicted.speclib", emit: spectral_library
        path "report-lib.*", optional: true

    script:
    """
    # Copy fasta files to working directory (config expects fasta/ subdirectory)
    mkdir -p fasta
    cp ${fasta_dir}/*.fasta fasta/

    /diann-${params.diann_version}/diann-linux \
        --cfg ${config_dir}/diann_speclib_config.cfg
    """
}

// Run DIA-NN search
process diann_search {

    label 'large'
    
    publishDir "${params.outdir}", mode: 'copy'

    input:
        path raw_dir
        path fasta_dir
        path config_dir
        path spectral_library

    output:
        path "*.*"

    script:
    """
    # Copy fasta files to working directory (config expects fasta/ subdirectory)
    mkdir -p fasta
    cp ${fasta_dir}/*.fasta fasta/

    /diann-${params.diann_version}/diann-linux \
        --cfg ${config_dir}/diann_search_config.cfg \
        --dir ${raw_dir} \
        --lib ${spectral_library}
    """
}

// Workflow
workflow {

    def (lib, _unused_report) = generate_library(
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
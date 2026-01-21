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
    variable_fastas=`ls fasta/*.fasta 2>/dev/null | grep -v "contams\\.fasta$" || true`
    if [ -z "\$variable_fastas" ]; then
        echo "No variable FASTA found in fasta/ (expected *.fasta besides contams.fasta)" >&2
        exit 1
    fi

    fasta_args=""
    for f in \$variable_fastas; do
        fasta_args+=" --fasta \$f"
    done

    /diann-${params.diann_version}/diann-linux \
        --cfg ${config_dir}/diann_speclib_config.cfg \$fasta_args
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
    variable_fastas=`ls fasta/*.fasta 2>/dev/null | grep -v "contams\\.fasta$" || true`
    if [ -z "\$variable_fastas" ]; then
        echo "No variable FASTA found in fasta/ (expected *.fasta besides contams.fasta)" >&2
        exit 1
    fi

    fasta_args=""
    for f in \$variable_fastas; do
        fasta_args+=" --fasta \$f"
    done

    /diann-${params.diann_version}/diann-linux \
        --cfg ${config_dir}/diann_search_config.cfg \
        --dir ${raw_dir} \
        --lib ${spectral_library} \
        \$fasta_args
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
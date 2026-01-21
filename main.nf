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
    # Debug: show what's staged
    echo "=== Work directory contents ==="
    ls -la
    echo "=== Fasta_dir value: ${fasta_dir} ==="
    echo "================================"
    
    fasta_args=""
    
    # Always add contaminant FASTA
    if [ -f "${fasta_dir}/contams.fasta" ]; then
        fasta_args=" --fasta ${fasta_dir}/contams.fasta"
    fi
    
    found_fasta=false
    
    # Add variable FASTA files
    for f in ${fasta_dir}/*.fasta; do
        if [ -f "\$f" ] && [ "\$(basename \$f)" != "contams.fasta" ]; then
            fasta_args+=" --fasta \$f"
            found_fasta=true
        fi
    done
    
    if [ "\$found_fasta" = "false" ]; then
        echo "No variable FASTA found in ${fasta_dir}/ (expected *.fasta besides contams.fasta)" >&2
        exit 1
    fi

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
    fasta_args=""
    
    # Always add contaminant FASTA
    if [ -f "${fasta_dir}/contams.fasta" ]; then
        fasta_args=" --fasta ${fasta_dir}/contams.fasta"
    fi
    
    found_fasta=false
    
    # Add variable FASTA files
    for f in ${fasta_dir}/*.fasta; do
        if [ -f "\$f" ] && [ "\$(basename \$f)" != "contams.fasta" ]; then
            fasta_args+=" --fasta \$f"
            found_fasta=true
        fi
    done
    
    if [ "\$found_fasta" = "false" ]; then
        echo "No variable FASTA found in ${fasta_dir}/ (expected *.fasta besides contams.fasta)" >&2
        exit 1
    fi

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
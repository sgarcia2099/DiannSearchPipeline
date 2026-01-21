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

// Package results for export
process package_results {

    label 'small'
    
    publishDir "${params.outdir}", mode: 'copy', pattern: "*.tar.gz"

    input:
        path results_dir
        path search_output
        path raw_dir
        path fasta_dir

    output:
        path "diann_results_*.tar.gz"

    script:
    """
    # Create timestamped archive name
    TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
    ARCHIVE_NAME="diann_results_\${TIMESTAMP}.tar.gz"
    
    # Create temporary directory for results to archive
    mkdir -p results_package
    
    # Copy all results (publishDir outputs)
    if [ -d "${results_dir}" ]; then
        cp -r ${results_dir}/* results_package/ 2>/dev/null || true
    fi
    
    # Remove large files we don't want to export
    find results_package -type f -name "*.raw" -delete 2>/dev/null || true
    find results_package -type f -name "*.fasta" -delete 2>/dev/null || true
    
    # Create compressed archive
    tar -czf "\${ARCHIVE_NAME}" results_package/
    
    echo "Created export package: \${ARCHIVE_NAME}"
    echo "Excluded .raw and .fasta files for minimal size"
    """
}

// Workflow
workflow {

    def (lib, _unused_report) = generate_library(
        fasta_dir,
        config_dir
    )

    def search_results = diann_search(
        raw_dir,
        fasta_dir,
        config_dir,
        lib
    )

    package_results(
        file(params.outdir),
        search_results,
        raw_dir,
        fasta_dir
    )
}
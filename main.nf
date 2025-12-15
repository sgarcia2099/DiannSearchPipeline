#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Parameters
params.raw_file = null
params.raw_dir  = null
params.outdir   = 'results'

// Input Channel
// Accept either one raw file OR a directory of raw files
Channel
    .fromPath(
        params.raw_file 
            ? params.raw_file 
            : "${params.raw_dir}/*.raw"
    )
    .set { raw_files }


// Process: Convert .raw → .mzML
process convert_to_mzML {
    tag "$rawFile"
    label 'med'

    publishDir params.outdir, mode: 'copy'

    container 'quay.io/biocontainers/thermorawfileparser:1.4.5--h05cac1d_1'

    input:
        path rawFile

    output:
        path "${rawFile.simpleName}.mzML"

    script:
    """
    convert_to_mzML.sh "${rawFile}"
    """
}


// Workflow definition
workflow {
    convert_to_mzML(raw_files)
}

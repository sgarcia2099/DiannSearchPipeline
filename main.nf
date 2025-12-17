#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Input channel
Channel
    .fromPath("${params.raw_dir}/*.raw", checkIfExists: true)
    .set { raw_files }

// Process: RAW → mzML
process convert_to_mzML {

    publishDir params.outdir, mode: 'copy'

    input:
        path rawFile

    output:
        path "${rawFile.simpleName}.mzML"

    script:
    """
    convert_to_mzML.sh "${rawFile}"
    """
}

// Workflow
workflow {
    convert_to_mzML(raw_files)
}

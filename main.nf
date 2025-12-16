#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// --------------------
// Parameters
// --------------------
params.raw_dir = null
params.outdir  = 'results'

// --------------------
// Input channel
// --------------------
Channel
    .fromPath(file("${params.raw_dir}/*.raw"))
    .set { raw_files }

// --------------------
// Process: RAW → mzML
// --------------------
process convert_to_mzML {

    tag { rawFile.simpleName }
    label 'med'

    publishDir params.outdir, mode: 'copy'

    //container 'quay.io/biocontainers/thermorawfileparser:1.4.5--h05cac1d_1'

    input:
        path rawFile

    output:
        path "${rawFile.simpleName}.mzML"

    script:
    """
    convert_to_mzML.sh "${rawFile}"
    """
}

// --------------------
// Workflow
// --------------------
workflow {
    convert_to_mzML(raw_files)
}

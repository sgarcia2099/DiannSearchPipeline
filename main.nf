#!/usr/bin/env nextflow

params.rawDir = "/path/to/rawfiles"   // override via --rawDir
params.batchSize = 5                   // number of raw files per process

workDir = "/scratch/$USER/nextflow_work"

Channel
    .fromPath("${params.rawDir}/*.raw")
    .batch(params.batchSize)          // group raw files
    .set { rawFileBatches }

process convert_to_mzML_batch {

    label 'large'
    publishDir "results/output", mode: 'link'

    input:
    path batchFiles

    output:
    path "*.mzML"    // all outputs from this batch

    script:
    """
    for rawFile in ${batchFiles} ; do
        bash ${workflow.projectDir}/convert_to_mzML.sh -i \$rawFile
    done
    """
}

// Workflow
workflow {
    rawFileBatches | convert_to_mzML_batch
}

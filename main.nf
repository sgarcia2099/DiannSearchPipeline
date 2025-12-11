#!/usr/bin/env nextflow

params.rawDir = "$baseDir/raw"
params.outDir = "results/mzML"

Channel
    .fromPath("${params.rawDir}/*.raw")
    .set { rawFiles }

process convert_to_mzML {
    tag "$rawFile"
    label 'med'

    publishDir params.outDir, mode: 'copy'

    container "containers/TRFP.sif"

    input:
    path rawFile

    output:
    path "${rawFile.simpleName}.mzML"

    script:
    """
    convert_to_mzML.sh ${rawFile}
    """
}

workflow {
    convert_to_mzML(rawFiles)
}

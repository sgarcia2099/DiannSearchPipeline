// Nextflow script for converting multiple Thermo .raw files to mzML
params.rawDir="path/to/rawfiles"

Channel
    .fromPath("${params.rawDir}/*.raw")
    .set { rawFiles }

process convert_to_mzML {
    publishDir "results/output", mode: 'link'

    input:
    path rawFile

    output:
    path "${rawFile.simpleName}.mzML", emit: mzMLFile

    script:
    """
    bash ${workflow.projectDir}/convert_to_mzML.sh -i ${rawFile}
    """
}

// Workflow
workflow {
    rawFiles | convert_to_mzML
}

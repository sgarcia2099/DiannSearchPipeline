// Nextflow script for converting multiple Thermo .raw files to mzML
params.file=""

process convert_to_mzML {
    publishDir "results/output"

    input:
    path rawFile

    output:
    path mzMLFile

    script:
    """
    ./convert_to_ mzML.sh -i ${rawFile} -o ${mzmLFile}
    """
}

// Workflow
workflow {
    channel.of(params.file)
        | convert_to_mzML
}

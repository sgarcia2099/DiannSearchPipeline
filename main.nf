#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Default DIA-NN version
params.diann_version = params.diann_version ?: '2.3.1'

// Input channel
Channel
    .fromPath("${params.raw_dir}/*.raw", checkIfExists: true)
    .set { raw_files }

// Process: RAW → mzML
process convert_to_mzML {
    
    container = 'quay.io/biocontainers/thermorawfileparser-1.4.5--h05cac1d_1'
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

// Run DIA-NN search
process diann_search {

    container = "garciasarah2099/diannpipeline:${params.diann_version}"
    publishDir params.outdir, mode: 'copy'

    input:
        path mzML_files

    output:
        path "*.tsv"

    script:
    """
    echo 'This is where the DIA-NN command goes' > test.tsv
    """
}

// Workflow
workflow {
    diann_search(
        convert_to_mzML(raw_files)
            .collect()
    )
}

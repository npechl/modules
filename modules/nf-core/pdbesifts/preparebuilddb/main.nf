process PDBESIFTS_PREPAREBUILDDB {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE'
        : 'quay.io/biocontainers/YOUR-TOOL-HERE'}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}.fasta.gz"), emit: fasta
    tuple val(meta), path("${prefix}.tsv"), emit: tax_mapping
    tuple val("${task.process}"), val('pdbe_sifts'), eval("pdbe_sifts --version | sed 's/pdbe_sifts //'"), topic: versions, emit: versions_pdbesifts

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    // Without an input FASTA, the tool downloads UniProt Swiss-Prot
    def input = fasta ? "--input-fasta ${fasta}" : ''
    if ("${fasta}" == "${prefix}.fasta.gz") {
        error("Input and output names are the same, set prefix in module configuration to disambiguate!")
    }
    """
    pdbe_sifts \\
        prepare_build_db \\
        ${args} \\
        ${input} \\
        --output-fasta ${prefix}.fasta.gz \\
        --output-tax-mapping ${prefix}.tsv
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip > ${prefix}.fasta.gz
    touch ${prefix}.tsv
    """
}

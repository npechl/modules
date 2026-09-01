process PDBESIFTS_BUILDDB {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/00/00bfe5269a959dbc72993abaa314164cf1e720d56769ff438adcae89155eab8a/data'
:         'community.wave.seqera.io/library/blast_mmseqs2_c-compiler_pip_pruned:f0136bed7613f457' }"

    input:
    tuple val(meta), path(fasta), path(tax_mapping)

    output:
    tuple val(meta), path("${prefix}"), emit: db
    tuple val("${task.process}"), val('pdbe_sifts'), eval("python -m pip show pdbe_sifts | sed -n 's/^Version: //p'"), topic: versions, emit: versions_pdbesifts

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}

    pdbe_sifts \\
        build_db \\
        -i ${fasta} \\
        -o ${prefix}/${prefix} \\
        -t ${tax_mapping} \\
        --threads ${task.cpus} \\
        $args

    rm -rf ${prefix}/tmp
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}
    touch ${prefix}/${prefix}
    touch ${prefix}/${prefix}.dbtype
    touch ${prefix}/${prefix}.index
    touch ${prefix}/${prefix}.lookup
    touch ${prefix}/${prefix}_h
    touch ${prefix}/${prefix}_h.index
    """
}

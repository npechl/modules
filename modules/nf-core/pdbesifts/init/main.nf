process PDBESIFTS_INIT {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/1c/1c83c25847b04ed869435ab1c9206ba9ecbf7edf4be1358722af463f4ca5364c/data'
:         'community.wave.seqera.io/library/c-compiler_pip_python_pdbe-sifts:afd1ce0583b7dd3e' }"

    input:
    val(meta)

    output:
    tuple val(meta), path("${prefix}"), emit: sifts_config
    tuple val("${task.process}"), val('pdbe_sifts'), eval("python -m pip show pdbe_sifts | sed -n 's/^Version: //p'"), topic: versions, emit: versions_pdbesifts

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    // pdbe_sifts always reads/writes its cache (UniProt-PDB xrefs, NCBI taxonomy) under
    // platformdirs' user config/data dirs, which resolve relative to $HOME, not --dest.
    // Redirecting HOME into the task directory is the only way to capture and namespace them.
    """
    export HOME="\$PWD/${prefix}"
    mkdir -p "\$HOME"

    pdbe_sifts \\
        init \\
        $args
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}/.config/pdbe_sifts
    touch ${prefix}/.config/pdbe_sifts/config.yaml
    echo "" | gzip > ${prefix}/.config/pdbe_sifts/uniprot_pdb.tsv.gz
    touch ${prefix}/.config/pdbe_sifts/uniprot_pdb.duckdb
    """
}

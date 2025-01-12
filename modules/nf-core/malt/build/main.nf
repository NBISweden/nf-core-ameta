process MALT_BUILD {

    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/malt:0.62--hdfd78af_0' :
        'biocontainers/malt:0.62--hdfd78af_0' }"

    input:
    path fastas
    path gff
    path mapping_db

    output:
    path "malt_index/"   , emit: index
    path "versions.yml"  , emit: versions
    path "malt-build.log", emit: log

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def igff = gff ? "-igff ${gff}" : ""

    """
    malt-build \\
        -v \\
        --input ${fastas.join(' ')} \\
        $igff \\
        -d 'malt_index/' \\
        -t $task.cpus \\
        $args \\
        --acc2taxa ${mapping_db} |& tee malt-build.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        malt: \$( malt-build --help |& sed '/version/!d; s/.*version //; s/,.*//' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    touch malt-build.log
    mkdir malt_index/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        malt: \$(malt-run --help  2>&1 | grep -o 'version.* ' | cut -f 1 -d ',' | cut -f2 -d ' ')
    END_VERSIONS
    """
}

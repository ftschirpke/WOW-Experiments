process writeLargeFile {

    tag {seed}

    input:
    val seed
    val minSizeGB
    val maxSizeGB

    output: 
    tuple val(seed), path("file.txt")

    """
    fio --rw=write --name=test --size=${new Random((seed * (seed + 10) + 151232) as int).nextInt( ((maxSizeGB - minSizeGB) * 1024) as int ) + ((minSizeGB * 1024) as int) }MB --filename=file.txt | grep " WRITE: "
    ls -lh file.txt
    """

}

process combineFilesA {
    
    input:
    path "file?.txt"

    output:
    path "combined.txt"

    """
    cat file*.txt > combined.txt
    ls -lh
    """

}

process combineFilesB {
    
    input:
    path "file?.txt"

    output:
    path "combined.txt"

    """
    cat file*.txt > combined.txt
    ls -lh
    """

}

workflow {
    seeds = Channel.of(1..params.numberOfTasks)
    writeLargeFile(seeds, params.minSizeGB, params.maxSizeGB)
    combineFilesA( writeLargeFile.out.map{ [ (it[0] / 3) as int, it[1] ] }.groupTuple(by: 0).map{ it[1] } )
    combineFilesB( writeLargeFile.out.map{ [ (it[0] / 4) as int, it[1] ] }.groupTuple(by: 0).map{ it[1] } )
}


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

process revertFile {

    tag {seed}

    input:
    tuple val(seed), path("file.txt")

    output: 
    path "fileReversed.txt"

    """
    tac file.txt > fileReversed.txt
    ls -lh file.txt
    md5sum file.txt fileReversed.txt
    """

}

process combineFiles {
    
    input:
    path "file?.txt"

    output:
    path "combined.txt"

    """
    cat file*.txt > combined.txt
    ls -lh
    """

}

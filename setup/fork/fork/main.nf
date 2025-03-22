include { writeLargeFile; revertFile } from './tasks'

workflow {
    writeLargeFile(1, params.minSizeGB, params.maxSizeGB)
    seeds = Channel.of(1..params.numberOfTasks)
    revertFile(seeds.combine( writeLargeFile.out ).map{ it[0,2] })
}


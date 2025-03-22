include { writeLargeFile; revertFile } from './tasks'

workflow {
    seeds = Channel.of(1..params.numberOfTasks)
    writeLargeFile(seeds, params.minSizeGB, params.maxSizeGB)
    revertFile(writeLargeFile.out)
}


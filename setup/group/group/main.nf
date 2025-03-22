include { writeLargeFile; combineFiles } from './tasks'

workflow {
    seeds = Channel.of(1..params.numberOfTasks)
    writeLargeFile(seeds, params.minSizeGB, params.maxSizeGB)
    combineFiles( writeLargeFile.out.map{ [ (it[0] / 3) as int, it[1] ] }.groupTuple(by: 0).map{ it[1] } )
}


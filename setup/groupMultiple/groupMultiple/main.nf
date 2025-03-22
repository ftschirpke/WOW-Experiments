include { writeLargeFile; combineFiles as combineFilesA; combineFiles as combineFilesB } from './tasks'

workflow {
    seeds = Channel.of(1..params.numberOfTasks)
    writeLargeFile(seeds, params.minSizeGB, params.maxSizeGB)
    combineFilesA( writeLargeFile.out.map{ [ (it[0] / 3) as int, it[1] ] }.groupTuple(by: 0).map{ it[1] } )
    combineFilesB( writeLargeFile.out.map{ [ (it[0] / 4) as int, it[1] ] }.groupTuple(by: 0).map{ it[1] } )
}


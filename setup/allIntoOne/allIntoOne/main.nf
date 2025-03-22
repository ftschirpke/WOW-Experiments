include { writeLargeFile; combineFiles } from './tasks'

workflow {
    seeds = Channel.of(1..params.numberOfTasks)
    writeLargeFile(seeds, params.minSizeGB, params.maxSizeGB)
    combineFiles( writeLargeFile.out.map{ it[1] }.buffer( size: Integer.MAX_VALUE, remainder: true ) )
}


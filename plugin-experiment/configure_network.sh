#!/usr/bin/env bash

slow_nodes=( c23 c24 c29 c32 )
fast_nodes=( c25 c27 c33 c41 )
all_nodes=( "${fast_nodes[@]}" "${slow_nodes[@]}" )

fast_value="2Gbit/s"
slow_value="1Gbit/s"

bench_file="dfs_io_benchmarks.txt"

fio_command="fio --name=seqrw --rw=readwrite --direct=1 --ioengine=libaio --bs=128k --iodepth=64 --size=12G --runtime=20"

for node in "${all_nodes[@]}"
do
    node_name="hu-worker-$node"
    echo "Current network configuration on node $node_name"
    pod=$(kubectl get pods -o wide | grep ft-nodes-for-tcconfig | grep $node_name | awk '{print $1}')
    kubectl exec -it $pod -- sh -c "tcshow eno1np0"
done

read -p "Press enter to configure new values"

for node in "${fast_nodes[@]}"
do
    node_name="hu-worker-$node"
    echo "Configure fast network for node $node_name"
    pod=$(kubectl get pods -o wide | grep ft-nodes-for-tcconfig | grep $node_name | awk '{print $1}')
    # kubectl exec -it $pod -- sh -c "tcset eno1np0 --rate $fast_value --overwrite"
    kubectl exec -it $pod -- sh -c "tcdel eno1np0"
    kubectl exec -it $pod -- sh -c "tcshow eno1np0"
done

exit 0


for node in "${slow_nodes[@]}"
do
    node_name="hu-worker-$node"
    echo "Configure slow network for node $node_name"
    pod=$(kubectl get pods -o wide | grep ft-nodes-for-tcconfig | grep $node_name | awk '{print $1}')
    # kubectl exec -it $pod -- sh -c "tcset eno1np0 --rate $slow_value --overwrite"
    kubectl exec -it $pod -- sh -c "tcdel eno1np0"
    kubectl exec -it $pod -- sh -c "tcshow eno1np0"
done

read -p "Press enter to continue with benchmarking"

echo > $bench_file

for node in "${all_nodes[@]}"
do
    node_name="hu-worker-$node"
    echo "Benchmark DFS I/O on node $node_name"
    pod=$(kubectl get pods -o wide | grep ft-nodes-for-tcconfig | grep $node_name | awk '{print $1}')
    echo "=== $node_name ===" >> $bench_file
    kubectl exec -it $pod -- sh -c "cd /experiments/wow_plugin_results && $fio_command" >> $bench_file
    echo >> $bench_file
    echo >> $bench_file
done

    


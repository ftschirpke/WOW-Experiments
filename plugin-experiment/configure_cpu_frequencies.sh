#!/usr/bin/env bash

slow_nodes=( )
fast_nodes=( c23 c24 c25 c27 c29 c32 c33 c41 )
all_nodes=( "${fast_nodes[@]}" "${slow_nodes[@]}" )

fast_value="3400MHz"
slow_value="2200MHz"

cpu_bench_file="cpu_benchmarks.txt"
mem_bench_file="mem_benchmarks.txt"

sysbench_cpu_command="sysbench cpu --threads=1 --cpu-max-prime=20000 run"
sysbench_mem_command="sysbench --test=memory --memory-block-size=1M --memory-total-size=100G --num-threads=1 run"

for node in "${all_nodes[@]}"
do
    node_name="hu-worker-$node"
    echo "Current CPU configuration on node $node_name"
    pod=$(kubectl get pods -o wide | grep ft-nodes-for-cpupower | grep $node_name | awk '{print $1}')
    kubectl exec -it $pod -- sh -c "cpupower frequency-info"
done

read -p "Press enter to configure new values"

for node in "${fast_nodes[@]}"
do
    node_name="hu-worker-$node"
    echo "Configure fast network for node $node_name"
    pod=$(kubectl get pods -o wide | grep ft-nodes-for-cpupower | grep $node_name | awk '{print $1}')
    kubectl exec $pod -- sh -c "cpupower -c all frequency-set -u $fast_value" > /dev/null
    kubectl exec -it $pod -- sh -c "cpupower frequency-info"
done


for node in "${slow_nodes[@]}"
do
    node_name="hu-worker-$node"
    echo "Configure slow network for node $node_name"
    pod=$(kubectl get pods -o wide | grep ft-nodes-for-cpupower | grep $node_name | awk '{print $1}')
    kubectl exec $pod -- sh -c "cpupower -c all frequency-set -u $slow_value" > /dev/null
    kubectl exec -it $pod -- sh -c "cpupower frequency-info"
done

read -p "Press enter to continue with benchmarking"

echo > $cpu_bench_file
echo > $mem_bench_file

for node in "${all_nodes[@]}"
do
    node_name="hu-worker-$node"
    echo "Benchmark CPU and Memory on node $node_name"
    pod=$(kubectl get pods -o wide | grep ft-nodes-for-cpupower | grep $node_name | awk '{print $1}')

    echo "=== $node_name ===" >> $cpu_bench_file
    kubectl exec -it $pod -- sh -c "$sysbench_cpu_command" >> $cpu_bench_file
    echo >> $cpu_bench_file
    echo >> $cpu_bench_file

    echo "=== $node_name ===" >> $mem_bench_file
    kubectl exec -it $pod -- sh -c "$sysbench_mem_command" >> $mem_bench_file
    echo >> $mem_bench_file
    echo >> $mem_bench_file
done

    


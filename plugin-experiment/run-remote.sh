cd $(dirname $0)

export KUBECONFIG="secrets/kubeconfig.yaml"
namespace=ftschirpke

# setup remote cluster
kubectl apply -f cluster/accounts.yaml -n $namespace
kubectl apply -f cluster/pvc.yaml -n $namespace
kubectl apply -f cluster/nextflow-pod-with-nfs.yaml -n $namespace

kubectl wait --timeout=100s --for=condition=ready pod nextflow -n $namespace && pod_ready=true || pod_ready=false
if [ $pod_ready = false ]; then
    echo "Unable to start nextflow pod on remote cluster. Exiting."
    exit 1
fi

kubectl exec -n $namespace nextflow -- bash -c "yum install -y tar openssh sshpass rsync findutils"
kubectl exec -n $namespace nextflow -- bash -c "cd /usr/local/bin/ && curl -LO 'https://dl.k8s.io/release/v1.28.3/bin/linux/amd64/kubectl' && chmod 700 kubectl"

echo "Copying experiment directory to remote cluster"
kubectl exec -n $namespace nextflow -- bash -c "rm -rf /experiments/experiment/ && mkdir -p /experiments/experiment"
kubectl cp ../plugin-experiment nextflow:/experiments
kubectl exec -n $namespace nextflow -- bash -c "mv /experiments/plugin-experiment/* /experiments/experiment && rm -rd /experiments/plugin-experiment"

results_dir=/experiments/wow_plugin_results
logname=$(date +%Y%m%d-%H%M%S).log

# run experiment on remote cluster
kubectl exec -n $namespace nextflow -- bash -c "mkdir -p $results_dir && nohup bash run.sh &> $results_dir/$logname & echo 'Successfully started remote experiment. DONE.'"

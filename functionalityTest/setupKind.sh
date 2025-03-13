k8sConfig=/home/friedrich/.kube/config
cluster=cws-kind

# delete kind cluster if it exists
sudo kind delete cluster --name $cluster

# clean and create folders for data
sudo rm -r /tmp/kind/data/shared /dev/shm/kind/localfiles/nodeC /dev/shm/kind/localfiles/node1 /dev/shm/kind/localfiles/node2 /dev/shm/kind/localfiles/node3 /tmp/kind/data/nfs /tmp/kind/data/shared-experiments
sudo mkdir -p /tmp/kind/data/shared /dev/shm/kind/localfiles/nodeC /dev/shm/kind/localfiles/node1 /dev/shm/kind/localfiles/node2 /dev/shm/kind/localfiles/node3 /tmp/kind/data/nfs /tmp/kind/data/shared-experiments

# create kind cluster
sudo kind create cluster --config kind-config.yaml --kubeconfig $k8sConfig
sudo chmod +rw $k8sConfig
kubectl config set-context --current --namespace=flehmann

#allow scheduling to master
kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-

# label the nodes
kubectl label nodes --all usedby=flehmann
kubectl label nodes $cluster-control-plane management=true

# set namespace to flehmann
kubectl create ns flehmann
kubectl config set-context --current --namespace=flehmann

# create the shared pvcs
kubectl apply -f pv-data.yaml

kubectl apply -f ../setup/download-pod.yaml

kubectl wait --for=condition=ready pod download-pod -n flehmann --timeout=30m
sleep 10

# download the inputs for the pattern experiments (smallest ones)
cd ../setup
bash setup-inputs.sh allIntoOne
bash setup-inputs.sh chain
bash setup-inputs.sh fork
bash setup-inputs.sh group
bash setup-inputs.sh groupMultiple

kubectl delete pod download-pod -n flehmann

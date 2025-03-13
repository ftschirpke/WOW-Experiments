bash load-images.sh

kubectl apply -f ../experiment/accounts.yaml
kubectl apply -f ../experiment/$1-pod.yaml
kubectl wait --for=condition=ready pod nextflow --timeout=30m
kubectl exec nextflow -- bash -c "apk add tar rsync openssh sshpass || yum install tar rsync openssh-server openssh-clients sshpass wget -y; wget https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm; rm epel-release-6-8.noarch.rpm; yum --enablerepo=epel -y install sshpass"
kubectl exec nextflow -- bash -c "cd /usr/local/bin/ && curl -LO 'https://dl.k8s.io/release/v1.28.3/bin/linux/amd64/kubectl' && chmod 700 kubectl"

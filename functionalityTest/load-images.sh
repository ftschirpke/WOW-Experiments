cluster=cws-kind

sudo kind load docker-image fabianlehmann/test1:fio --name $cluster

sudo kind load docker-image nf-adjusted:latest --name $cluster
sudo kind load docker-image nf-orig:latest --name $cluster
sudo kind load docker-image commonworkflowscheduler/kubernetesscheduler:2.0 --name $cluster

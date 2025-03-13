cluster=cws-kind

sudo kind load docker-image fabianlehmann/test1:fio --name $cluster

sudo kind load docker-image fabianlehmann/test1:nxf_vla_exp --name $cluster
sudo kind load docker-image friedricht/nf-cws-ref:latest --name $cluster
sudo kind load docker-image friedricht/nf-cws-wow:latest --name $cluster
sudo kind load docker-image nf-adjusted:latest --name $cluster
sudo kind load docker-image nf-orig:latest --name $cluster
sudo kind load docker-image fabianlehmann/test1:sch_v201 --name $cluster
sudo kind load docker-image fabianlehmann/test1:sch_v303 --name $cluster

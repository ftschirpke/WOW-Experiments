
kubectl exec nextflow -- /bin/bash -c "rm -rdf /.nextflow/plugins/nf-cws-1.1.0"
kubectl cp ~/shk-leser/nf-cws/build/plugins/nf-cws-1.1.0 nextflow:/.nextflow/plugins

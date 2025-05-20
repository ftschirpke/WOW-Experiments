NFCWS_VERSION=2.0.0

kubectl exec nextflow -- /bin/bash -c "rm -rdf /.nextflow/plugins/nf-cws-${NFCWS_VERSION}"
kubectl cp ~/shk-leser/nf-cws/build/plugins/nf-cws-${NFCWS_VERSION} nextflow:/.nextflow/plugins

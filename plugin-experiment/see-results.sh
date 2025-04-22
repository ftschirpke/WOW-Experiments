kubectl wait --timeout=100s --for=condition=ready pod nextflow && pod_ready=true || pod_ready=false

kubectl exec --tty --stdin nextflow -- bash -c "cd /experiments/wow_plugin_results; bash"

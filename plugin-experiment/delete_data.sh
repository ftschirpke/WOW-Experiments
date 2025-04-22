#!/usr/bin/env bash

export KUBECONFIG="secrets/kubeconfig.yaml"
namespace=ftschirpke

kubectl exec -n $namespace nextflow -- bash -c "rm -rd /experiments/experiment/*"
kubectl exec -n $namespace nextflow -- bash -c "rm -rd /input/data"

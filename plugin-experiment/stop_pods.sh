#!/usr/bin/env bash

export KUBECONFIG="secrets/kubeconfig.yaml"

kubectl delete ds -l app=nextflow --wait
kubectl delete pods -l app=nextflow --wait
kubectl delete pods -l nextflow.io/app=nextflow --wait


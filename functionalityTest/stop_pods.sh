#!/usr/bin/env bash

kubectl delete ds -l app=nextflow --wait
kubectl delete pods -l app=nextflow --wait
kubectl delete pods -l nextflow.io/app=nextflow --wait


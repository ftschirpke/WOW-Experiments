#!/usr/bin/env bash

kubectl get pod | grep Terminating | awk '{ print $1 }' | xargs kubectl delete pod --force

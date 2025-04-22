if [[ $# -eq 0 ]]; then
    pod=nextflow
elif [[ $# -eq 1 ]]; then
    pod=$1
elif [[ $# -gt 1 ]]; then
    echo "Usage: go-to-pod.sh [pod]"
    exit 1
fi

kubectl exec --tty --stdin $pod -- bash

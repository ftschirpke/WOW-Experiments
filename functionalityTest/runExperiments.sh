if [ "$1" != "ceph" ] && [ "$1" != "nfs" ] && [ "$1" != "orig-ceph" ] && [ "$1" != "orig-nfs" ]
then
    echo "No storage supplied (ceph/nfs)"
    exit 1
fi

# if $1 starts with orig, only take second part
if [[ "$1" == orig* ]]; then
    NXF_ORIG=true
    storage=${1:5}
else
    NXF_ORIG=false
    storage=$1
fi
speed=$2
reruns=3 # Runs for each workflow + 1
namespace=$(cat namespace.txt)
workflows=( groupMultiple allIntoOne chain fork group )
nodes="4nodes"

collectData() {
    experiment=$1
    workflow=$2
    cp /input/data/output/report.html $experiment/report.html
    cp /input/data/output/trace.csv $experiment/trace.csv
    cp -r launch $experiment/
    cp /input/data/output/dag.html $experiment/dag.html
    cp /input/data/output/timeline.html $experiment/timeline.html
    cp /input/data/scheduler/copytasks.csv $experiment/copytasks.csv
    cp $workflow/nextflow.config $experiment/nextflow.config

    workData=`du -s /input/data/work | awk '{print$1}'`
    outData=`du -s /input/data/outdata | awk '{print$1}'`
    outputData=`du -s /input/data/output | awk '{print$1}'`
    echo "folder;size" > $experiment/dataOnSharedFS.csv
    echo "workData;$workData" > $experiment/dataOnSharedFS.csv
    echo "outData;$outData" >> $experiment/dataOnSharedFS.csv
    echo "outputData;$outputData" >> $experiment/dataOnSharedFS.csv

    bash collectLaData.sh > $experiment/dataOnNode.csv
}

cleanup(){
    kubectl delete ds -l app=nextflow --wait
    kubectl delete pods -l app=nextflow --wait
    kubectl delete pods -l nextflow.io/app=nextflow --wait
    kubectl apply -f cleanerData.yaml --wait
    kubectl rollout status daemonset cleaner
    kubectl delete -f cleanerData.yaml --wait
    rm /input/data -rf
    rm launch -rf
    kubectl delete pod workflow-scheduler --wait
}

waitForNodes(){
    # Confirm that all nodes are ready before starting
    SECONDS_BETWEEN_CHECKS=10

    while true; do
        NOT_READY_COUNT=$(kubectl get nodes --no-headers | grep -v "Ready" | wc -l)
        TOTAL_NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
        READY_COUNT=$((TOTAL_NODE_COUNT - NOT_READY_COUNT))

        if [ "$NOT_READY_COUNT" -eq 0 ]; then
            echo "All nodes are ready!"
            break
        else
            echo "$READY_COUNT out of $TOTAL_NODE_COUNT nodes are ready. $NOT_READY_COUNT nodes are not ready yet. Waiting..."
        fi

        sleep "$SECONDS_BETWEEN_CHECKS"
    done
}

if [ "$NXF_ORIG" = true ] ; then
    runs=( orig )
else
    # runs=( la cws )
    runs=( la )
    # runs=( cws )
fi

for workflow in "${workflows[@]}"
do  
    experiment=""
    for run in "${runs[@]}"
    do
        trial=1
        # check if workflow is already done
        while [ $trial -ne $reruns ]
        do
            experiment=/experiments/results/$nodes/$workflow/$run-$storage/$trial
            if [ ! -d "$experiment/launch" ]; then
                rm $experiment -rf
                mkdir -p $experiment
                break
            fi
            echo "Skipping $workflow $run $trial"
            trial=$(($trial+1))
        done
        if [ $trial -eq $reruns ]; then
            continue
        fi

        waitForNodes

        # copy data
        echo "workflow: $workflow: copying data"
        # github repo
        rsync -aL --chmod=755 --info=progress2 --size-only /nfs/$workflow/$workflow /input
        # input data
        rsync -aL --chmod=755 --info=progress2 --size-only /nfs/$workflow/input /input

        if [ -f /input/input/to_create.txt ]; then
            bash /input/input/create.sh /input/input/to_create.txt
        fi

        # make sure no data is left
        rm /input/data -rf

        # load to cache
        echo "workflow: $workflow: loading to cache"
        kubectl apply -f $workflow/loadToCache.yaml -n $namespace
        kubectl rollout status daemonset workflow-prepare -n $namespace
        kubectl delete -f $workflow/loadToCache.yaml --wait -n $namespace

        while [ $trial -ne $reruns ]
        do
            start=$(date '+%Y-%m-%d--%H-%M-%S')
            experiment=/experiments/results/$nodes/$workflow/$run-$storage/$trial
            if [ -d "$experiment/launch" ]; then
                trial=$(($trial+1))
                continue
            else
                rm $experiment -rf
                mkdir -p $experiment
            fi
            
            # start scheduler
            echo "workflow: $workflow $run-$storage ($trial): starting scheduler"

            kubectl apply -f $storage-workflow-scheduler.yaml --wait -n $namespace
            kubectl wait --for=condition=ready pod workflow-scheduler -n $namespace --timeout=30m
            nohup kubectl logs workflow-scheduler -f -n $namespace > $experiment/scheduler.log &
            
            # run on cluster
            echo "workflow: $workflow $run-$storage ($trial): running on cluster"
            # make sure no data is left
            rm launch -rf
            mkdir launch
            cd launch
            profile=""
            #check if a profile is specified
            if [ -f /experiments/experiment/$workflow/profile.txt ]; then
                profile="-profile $(cat /experiments/experiment/$workflow/profile.txt)"
            fi
            waitForNodes
            nextflow run /input/$workflow $profile -c /experiments/experiment/$workflow/nextflow.config -c /experiments/experiment/nextflow_$run-plugin.config -c /experiments/experiment/nextflow_$storage.config
            cd ..

            error=false
            # check that all nodes are ready and the workflow did not fail/was influenced because of a failed node
            # Only increase and store results, if this condition is met
            NOT_READY_COUNT=$(kubectl get nodes --no-headers | grep -v "Ready" | wc -l)
            if [ "$NOT_READY_COUNT" -eq 0 ]; then
                # store data
                echo "workflow: $workflow $run-$storage ($trial): storing data"
                collectData $experiment $workflow
            else
                error=true
                echo "workflow: $workflow $run-$storage ($trial): not all nodes are ready, retrying"
            fi

            echo "workflow: $workflow $run-$storage ($trial): cleaning up"
            cleanup

            if ! grep -q "Workflow execution completed successfully" "$experiment/report.html"; then
                error=true
                echo "workflow: $workflow $run-$storage ($trial): workflow failed, retrying"
                mv $experiment $experiment-failed-$start
            fi

            if [ "$error" = false ] ; then
                trial=$(($trial+1))
            fi
        done
    
    done

    # clean experiment inputs
    echo "workflow: $workflow: cleaning experiment inputs"
    rm /input/input/ -rf
    rm /input/$workflow/ -rf
done



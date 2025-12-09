#!/usr/bin/env bash
set -euo pipefail

# --- Argument Parsing ---
CONTEXT=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --context=*) CONTEXT="${1#*=}"; shift ;;
        --context) CONTEXT="$2"; shift; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
done

if [[ -z "$CONTEXT" ]]; then
    echo "Usage: $0 --context=<kube-context>"
    echo "Available contexts:"
    kubectl config get-contexts -o name
    exit 1
fi

# Wrapper function to run oc with the specified context
function oc_cmd() {
    oc --context="$CONTEXT" "$@"
}

NAMESPACE="cpu-benchmark-temp"
# Official sysbench image or a reliable alternative
IMAGE="quay.io/btofel/sysbench:latest" 

echo "=================================================="
echo "   Cluster Hardware Baseline"
echo "   Context: $CONTEXT"
echo "=================================================="

# 1. Get Instance Type from a Worker Node
WORKER_NODE=$(oc_cmd get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [[ -z "$WORKER_NODE" ]]; then
     # Fallback if no specific 'worker' label exists
     WORKER_NODE=$(oc_cmd get nodes -o jsonpath='{.items[0].metadata.name}')
fi

INSTANCE_TYPE=$(oc_cmd get node "$WORKER_NODE" -o jsonpath='{.metadata.labels.node\.kubernetes\.io/instance-type}' 2>/dev/null || echo "Unknown")
echo "Node: $WORKER_NODE"
echo "Instance Type: $INSTANCE_TYPE"

# 2. Run a Probe Job to get CPU Model and Run Benchmark
echo "==> Deploying benchmark pod..."

oc_cmd delete ns "$NAMESPACE" --ignore-not-found --wait=true >/dev/null 2>&1
oc_cmd create ns "$NAMESPACE" --dry-run=client -o yaml | oc_cmd apply -f - >/dev/null

cat <<EOF | oc_cmd apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: cpu-benchmark
  namespace: $NAMESPACE
spec:
  template:
    spec:
      nodeSelector:
        node-role.kubernetes.io/worker: ""
      containers:
      - name: benchmark
        image: $IMAGE
        command: ["/bin/bash", "-c"]
        args:
        - |
          echo "--- CPU Model ---"
          cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2 | xargs
          echo "--- Bogomips ---"
          cat /proc/cpuinfo | grep 'bogomips' | head -1 | cut -d: -f2 | xargs
          
          echo "--- Running Sysbench CPU Test ---"
          sysbench cpu --cpu-max-prime=20000 run
          
      restartPolicy: Never
EOF

echo "==> Waiting for benchmark to complete..."
oc_cmd wait --for=condition=complete job/cpu-benchmark -n "$NAMESPACE" --timeout=120s >/dev/null

echo "==> Results:"
oc_cmd logs job/cpu-benchmark -n "$NAMESPACE"

echo "=================================================="
echo "Cleaning up..."
oc_cmd delete ns "$NAMESPACE" --wait=false >/dev/null 2>&1

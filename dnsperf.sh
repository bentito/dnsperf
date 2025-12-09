#!/usr/bin/env bash
set -euo pipefail

# --- Argument Parsing ---
CONTEXT=""
QUERY_TYPE="mixed"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --context=*) CONTEXT="${1#*=}"; shift ;;
        --context) CONTEXT="$2"; shift; shift ;;
        --query-type=*) QUERY_TYPE="${1#*=}"; shift ;;
        --query-type) QUERY_TYPE="$2"; shift; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
done

if [[ -z "$CONTEXT" ]]; then
    echo "Usage: $0 --context=<kube-context> [--query-type=<internal|external|mixed>]"
    echo "Available contexts:"
    kubectl config get-contexts -o name
    exit 1
fi

# Wrapper function to run oc with the specified context
function oc_cmd() {
    oc --context="$CONTEXT" "$@"
}

# --- Configuration ---
NAMESPACE="dns-stress-test"
DURATION=60          # Seconds to run the test
QPS=2000             # Queries Per Second (Adjust based on cluster size)
IMAGE="quay.io/quay/busybox" # Base image (we will install dnsperf if needed or use a tool image)
# Note: We use a fedora-based image that allows easy installation or a specific tool image.
# Using a widely available image that can run a package manager or static binary is best.
# Here we use a community dnsperf image for simplicity.
TOOL_IMAGE="quay.io/btofel/dnsperf:latest" 

echo "=================================================="
echo "   OpenShift CoreDNS CPU Benchmark"
echo "   Target Context: $CONTEXT"
echo "   Target Cluster: $(oc_cmd whoami --show-server)"
echo "   Duration: ${DURATION}s | Target QPS: ${QPS}"
echo "=================================================="

# 1. Setup Namespace and Data
echo "==> Cleaning up previous run..."
oc_cmd delete ns "$NAMESPACE" --ignore-not-found --wait=true

echo "==> Setting up test namespace: $NAMESPACE"
oc_cmd create ns "$NAMESPACE" --dry-run=client -o yaml | oc_cmd apply -f -

# 2. Create the Query Data File (The "Relevant" Load)
# We create a ConfigMap containing the DNS query patterns.
# Format: <name> <record_type>
echo "==> Creating query payload (Type: $QUERY_TYPE)..."

case "$QUERY_TYPE" in
    internal)
        # Internal names with trailing dot to bypass search paths
        cat <<EOF > queryfile.txt
kubernetes.default.svc.cluster.local. A
kubernetes.default.svc.cluster.local. A
kubernetes.default.svc.cluster.local. A
kubernetes.default.svc.cluster.local. SRV
fake.entry.cluster.local. A
openshift.default.svc.cluster.local. A
EOF
        ;;
    external)
        # External names
        cat <<EOF > queryfile.txt
google.com. A
example.com. A
github.com. A
quay.io. A
registry.redhat.io. A
EOF
        ;;
    mixed|*)
        # Mixed workload
        cat <<EOF > queryfile.txt
kubernetes.default.svc.cluster.local A
kubernetes.default.svc.cluster.local A
kubernetes.default.svc.cluster.local A
kubernetes.default.svc.cluster.local SRV
google.com A
example.com A
nonexistent.service.local A
fake.entry.cluster.local A
EOF
        ;;
esac

oc_cmd create configmap dns-queries --from-file=queryfile.txt -n "$NAMESPACE" --dry-run=client -o yaml | oc_cmd apply -f -
rm queryfile.txt

# 3. Launch the Load Generator Job
echo "==> Launching dnsperf Job..."
# We use the Service IP of the cluster DNS (usually 172.30.0.10)
CLUSTER_DNS_IP=$(oc_cmd get svc -n openshift-dns dns-default -o jsonpath='{.spec.clusterIP}')

cat <<EOF | oc_cmd apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: dns-load-generator
  namespace: $NAMESPACE
spec:
  template:
    spec:
      containers:
      - name: dnsperf
        image: $TOOL_IMAGE
        command: ["dnsperf"]
        args:
          - "-s"
          - "$CLUSTER_DNS_IP"
          - "-d"
          - "/data/queryfile.txt"
          - "-l"
          - "$DURATION"
          - "-Q"
          - "$QPS"
        volumeMounts:
        - name: data
          mountPath: /data
      restartPolicy: Never
      volumes:
      - name: data
        configMap:
          name: dns-queries
EOF

# 4. Monitor CPU Usage Loop
echo "==> Waiting for Job to start..."

# Smart wait loop to detect ImagePull errors early
START_TIME=$SECONDS
MAX_WAIT=300
POD_READY=false

while [ $((SECONDS - START_TIME)) -lt $MAX_WAIT ]; do
    # Check if pod exists first
    POD_NAME=$(oc_cmd get pod -l job-name=dns-load-generator -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$POD_NAME" ]; then
        sleep 2
        continue
    fi

    # Check for Ready condition
    if oc_cmd get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null | grep -q "true"; then
        POD_READY=true
        break
    fi

    # Check for common failure states in waiting containers
    REASON=$(oc_cmd get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || echo "")
    
    if [[ "$REASON" == "ErrImagePull" ]] || [[ "$REASON" == "ImagePullBackOff" ]] || [[ "$REASON" == "InvalidImageName" ]]; then
        echo "ERROR: Pod failed to pull image. Reason: $REASON"
        echo "Image used: $TOOL_IMAGE"
        oc_cmd describe pod "$POD_NAME" -n "$NAMESPACE"
        exit 1
    fi

    sleep 5
done

if [ "$POD_READY" = false ]; then
    echo "ERROR: Timed out waiting for dnsperf pod to be ready."
    echo "--- Pod Status ---"
    oc_cmd get pods -n "$NAMESPACE"
    echo "--- Pod Description ---"
    oc_cmd describe pod -l job-name=dns-load-generator -n "$NAMESPACE"
    exit 1
fi

echo "==> Measuring CoreDNS CPU usage for $DURATION seconds..."
END_TIME=$((SECONDS + DURATION))
TOTAL_CPU_SUM=0
SAMPLES=0

# Header for CSV output if you want to pipe it
# echo "Timestamp,Total_CoreDNS_CPU_mCores"

while [ $SECONDS -lt $END_TIME ]; do
    # Get CPU usage of all pods in openshift-dns matching the daemonset
    # output is in millicores (e.g., 10m). We strip 'm' and sum them up.
    
    # Snapshot current usage
    # We capture stderr to a temporary file to check for errors, or just check if output is empty
    CURRENT_USAGE=$(oc_cmd adm top pods -n openshift-dns -l dns.operator.openshift.io/daemonset-dns=default --no-headers 2>/dev/null | awk '{sum += $3} END {print sum}')
    
    # Clean the 'm' unit if present (oc adm top usually returns '15m')
    CURRENT_USAGE=${CURRENT_USAGE%m}
    
    # Handle cases where top returns nothing/error
    if [[ -z "$CURRENT_USAGE" ]]; then
        echo "   [$(date +%T)] WARNING: Failed to retrieve CPU usage. Skipping sample."
    else
        echo "   [$(date +%T)] Cluster-wide CoreDNS CPU: ${CURRENT_USAGE}m"
        TOTAL_CPU_SUM=$((TOTAL_CPU_SUM + CURRENT_USAGE))
        SAMPLES=$((SAMPLES + 1))
    fi
    
    sleep 5
done

# 5. Calculate Results
if [ "$SAMPLES" -gt 0 ]; then
    AVG_CPU=$((TOTAL_CPU_SUM / SAMPLES))
else
    AVG_CPU=0
fi

echo "=================================================="
echo "   RESULTS"
echo "=================================================="
echo "   Average Cluster-wide CoreDNS CPU: ${AVG_CPU}m"
echo "=================================================="

# 6. Optional Cleanup
# echo "Cleaning up..."
# oc delete ns $NAMESPACE
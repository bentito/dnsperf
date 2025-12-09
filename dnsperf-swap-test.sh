#!/usr/bin/env bash
set -euo pipefail

# Hardcoded Context as requested
CONTEXT="openshift-4.19"
TARGET_IMAGE="quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:18504c088c4b54069cf75c2d7d2dc9dd3d0607c4ac9b6a3f6a302bd80f0890bc"

# Wrapper for oc
function oc_cmd() {
    oc --context="$CONTEXT" "$@"
}

echo "################################################################"
echo "#  CoreDNS A/B Test on Single Cluster ($CONTEXT)  #"
echo "################################################################"

# --- HELPER FUNCTIONS ---

function run_benchmark() {
    echo ""
    echo ">>> Running Version Verification..."
    ./verify-coredns-version.sh --context="$CONTEXT"
    
    echo ""
    echo ">>> Running Performance Test..."
    ./dnsperf.sh --context="$CONTEXT"
}

function stop_operators() {
    echo ""
    echo "!!! Pausing Cluster Operators to prevent reconciliation !!!"
    echo "Scaling down cluster-version-operator..."
    oc_cmd scale deploy/cluster-version-operator -n openshift-cluster-version --replicas=0
    
    echo "Scaling down dns-operator..."
    oc_cmd scale deploy/dns-operator -n openshift-dns-operator --replicas=0
}

function restore_operators() {
    echo ""
    echo "!!! Restoring Cluster Operators !!!"
    echo "Scaling up dns-operator..."
    oc_cmd scale deploy/dns-operator -n openshift-dns-operator --replicas=1
    
    echo "Scaling up cluster-version-operator..."
    oc_cmd scale deploy/cluster-version-operator -n openshift-cluster-version --replicas=1
    
    echo "Note: It may take a few minutes for the operators to revert CoreDNS version."
}

# --- EXECUTION FLOW ---

# Ensure we have the helper scripts
if [[ ! -x "./dnsperf.sh" ]] || [[ ! -x "./verify-coredns-version.sh" ]]; then
    echo "Error: ./dnsperf.sh or ./verify-coredns-version.sh not found or not executable."
    exit 1
fi

trap restore_operators EXIT

# 1. BASELINE TEST
echo ""
echo "================================================================"
echo " PHASE 1: BASELINE (Existing Version)"
echo "================================================================"
run_benchmark

# 2. SWAP IMAGE
echo ""
echo "================================================================"
echo " PHASE 2: SWAPPING IMAGE TO 1.13.1"
echo " Target: $TARGET_IMAGE"
echo "================================================================"

stop_operators

echo "Patching CoreDNS DaemonSet..."
oc_cmd set image ds/dns-default -n openshift-dns dns="$TARGET_IMAGE"

echo "Waiting for rollout..."
oc_cmd rollout status ds/dns-default -n openshift-dns --timeout=300s

# 3. UPGRADED TEST
echo ""
echo "================================================================"
echo " PHASE 3: UPGRADED TEST (Target Version)"
echo "================================================================"
run_benchmark

echo ""
echo "================================================================"
echo " TEST COMPLETE"
echo "================================================================"
# Trap will handle operator restoration

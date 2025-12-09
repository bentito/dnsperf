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

echo "=================================================="
echo "   Checking CoreDNS Version"
echo "   Context: $CONTEXT"
echo "   Cluster: $(oc_cmd whoami --show-server)"
echo "=================================================="

# Get one running pod from the daemonset
POD=$(oc_cmd get pods -n openshift-dns -l dns.operator.openshift.io/daemonset-dns=default -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [[ -z "$POD" ]]; then
    echo "Error: No CoreDNS pods found in openshift-dns namespace."
    exit 1
fi

echo "Querying binary version in pod: $POD"
echo "--------------------------------------------------"
oc_cmd exec -n openshift-dns "$POD" -c dns -- coredns --version
echo "--------------------------------------------------"


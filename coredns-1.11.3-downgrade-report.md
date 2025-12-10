# CoreDNS 1.11.3 Downgrade Performance Report

**Date:** December 10, 2025
**Cluster:** OpenShift 4.21 (AWS)
**Test Method:** A/B Swap on identical hardware (Single Cluster) with Split Internal/External Queries
**Tool:** `dnsperf` @ 2000 QPS

## Executive Summary

CoreDNS **1.13.1** (the baseline for OpenShift 4.21) consumed **significantly more CPU** than the older **1.11.3** version (from OpenShift 4.19) when running on the same 4.21 cluster hardware.

Downgrading to version **1.11.3** resulted in a substantial **reduction in CPU usage** across both internal and external query workloads.

| Version | Workload Type | Average CPU (mCores) | Delta (vs 1.13.1) |
| :--- | :--- | :--- | :--- |
| **1.13.1** (Baseline) | Internal (Cluster Local) | **294m** | - |
| **1.11.3** (Downgraded) | Internal (Cluster Local) | **220m** | **-74m (-25.2%)** |
| | | | |
| **1.13.1** (Baseline) | External (Upstream) | **296m** | - |
| **1.11.3** (Downgraded) | External (Upstream) | **227m** | **-69m (-23.3%)** |

## Conclusion

The newer CoreDNS version (1.13.1) exhibits a significant performance regression compared to the older version (1.11.3) in this environment.

*   **Internal Queries:** 1.11.3 is **~25% more efficient** than 1.13.1.
*   **External Queries:** 1.11.3 is **~23% more efficient** than 1.13.1.

This confirms that the increased resource consumption observed in OpenShift 4.21 is likely attributable to the CoreDNS software update itself, rather than environmental factors, as the older binary runs significantly more efficiently on the same newer platform.

---

## Appendix: Raw Execution Log

```text
$  export KUBECONFIG=$(pwd)/cluster-bot-2025-12-10-180542.kubeconfig && ./dnsperf-swap-test.sh
################################################################
#  CoreDNS A/B Test on Single Cluster (admin)  #
################################################################

================================================================
 PHASE 1: BASELINE (Existing Version)
================================================================

>>> Running Version Verification...
==================================================
   Checking CoreDNS Version
   Context: admin
   Cluster: https://api.ci-ln-t64rh1t-76ef8.aws-4.ci.openshift.org:6443
==================================================
Querying binary version in pod: dns-default-86cxm
--------------------------------------------------
CoreDNS-1.13.1
linux/amd64, go1.24.6 (Red Hat 1.24.6-1.el9_6) X:strictfipsruntime,
--------------------------------------------------

>>> Running Performance Test (INTERNAL Queries)...
==================================================
   OpenShift CoreDNS CPU Benchmark
   Target Context: admin
   Target Cluster: https://api.ci-ln-t64rh1t-76ef8.aws-4.ci.openshift.org:6443
   Duration: 60s | Target QPS: 2000
==================================================
==> Cleaning up previous run...
namespace "dns-stress-test" deleted
==> Setting up test namespace: dns-stress-test
namespace/dns-stress-test created
==> Creating query payload (Type: internal)...
configmap/dns-queries created
==> Launching dnsperf Job...
job.batch/dns-load-generator created
==> Waiting for Job to start...
==> Measuring CoreDNS CPU usage for 60 seconds...
   [15:24:46] Cluster-wide CoreDNS CPU: 295m
   [15:24:52] Cluster-wide CoreDNS CPU: 295m
   [15:24:58] Cluster-wide CoreDNS CPU: 295m
   [15:25:04] Cluster-wide CoreDNS CPU: 292m
   [15:25:10] Cluster-wide CoreDNS CPU: 292m
   [15:25:16] Cluster-wide CoreDNS CPU: 293m
   [15:25:22] Cluster-wide CoreDNS CPU: 293m
   [15:25:28] Cluster-wide CoreDNS CPU: 294m
   [15:25:33] Cluster-wide CoreDNS CPU: 295m
   [15:25:39] Cluster-wide CoreDNS CPU: 295m
   [15:25:46] Cluster-wide CoreDNS CPU: 295m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 294m
==================================================

>>> Running Performance Test (EXTERNAL Queries)...
==================================================
   OpenShift CoreDNS CPU Benchmark
   Target Context: admin
   Target Cluster: https://api.ci-ln-t64rh1t-76ef8.aws-4.ci.openshift.org:6443
   Duration: 60s | Target QPS: 2000
==================================================
==> Cleaning up previous run...
namespace "dns-stress-test" deleted
==> Setting up test namespace: dns-stress-test
namespace/dns-stress-test created
==> Creating query payload (Type: external)...
configmap/dns-queries created
==> Launching dnsperf Job...
job.batch/dns-load-generator created
==> Waiting for Job to start...
==> Measuring CoreDNS CPU usage for 60 seconds...
   [15:26:08] Cluster-wide CoreDNS CPU: 296m
   [15:26:14] Cluster-wide CoreDNS CPU: 296m
   [15:26:20] Cluster-wide CoreDNS CPU: 295m
   [15:26:26] Cluster-wide CoreDNS CPU: 296m
   [15:26:32] Cluster-wide CoreDNS CPU: 297m
   [15:26:38] Cluster-wide CoreDNS CPU: 297m
   [15:26:44] Cluster-wide CoreDNS CPU: 297m
   [15:26:50] Cluster-wide CoreDNS CPU: 297m
   [15:26:56] Cluster-wide CoreDNS CPU: 296m
   [15:27:01] Cluster-wide CoreDNS CPU: 297m
   [15:27:07] Cluster-wide CoreDNS CPU: 297m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 296m
==================================================

================================================================
 PHASE 2: SWAPPING IMAGE TO 1.11.3 (DOWNGRADE)
 Target: quay.io/openshift-release-dev/ocp-v4.0-art-dev @sha256:8346b755f20da14f192278b33cc68fbe777df45cb03fd0ebc1ce1758508b9899
================================================================

!!! Pausing Cluster Operators to prevent reconciliation !!!
Scaling down cluster-version-operator...
Warning: spec.template.spec.nodeSelector[node-role.kubernetes.io/master]: use "node-role.kubernetes.io/control-plane" instead
deployment.apps/cluster-version-operator scaled
Scaling down dns-operator...
Warning: spec.template.spec.nodeSelector[node-role.kubernetes.io/master]: use "node-role.kubernetes.io/control-plane" instead
deployment.apps/dns-operator scaled
Patching CoreDNS DaemonSet...
daemonset.apps/dns-default image updated
Waiting for rollout...
Waiting for daemon set "dns-default" rollout to finish: 0 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 0 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 1 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 1 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 2 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 2 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 3 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 3 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 4 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 4 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 5 out of 6 new pods have been updated...
Waiting for daemon set "dns-default" rollout to finish: 5 out of 6 new pods have been updated...
daemon set "dns-default" successfully rolled out

================================================================
 PHASE 3: UPGRADED TEST (Target Version)
================================================================

>>> Running Version Verification...
==================================================
   Checking CoreDNS Version
   Context: admin
   Cluster: https://api.ci-ln-t64rh1t-76ef8.aws-4.ci.openshift.org:6443
==================================================
Querying binary version in pod: dns-default-6zqv6
--------------------------------------------------
CoreDNS-1.11.3
linux/amd64, go1.23.9 (Red Hat 1.23.9-1.el9_6) X:strictfipsruntime,
--------------------------------------------------

>>> Running Performance Test (INTERNAL Queries)...
==================================================
   OpenShift CoreDNS CPU Benchmark
   Target Context: admin
   Target Cluster: https://api.ci-ln-t64rh1t-76ef8.aws-4.ci.openshift.org:6443
   Duration: 60s | Target QPS: 2000
==================================================
==> Cleaning up previous run...
namespace "dns-stress-test" deleted
==> Setting up test namespace: dns-stress-test
namespace/dns-stress-test created
==> Creating query payload (Type: internal)...
configmap/dns-queries created
==> Launching dnsperf Job...
job.batch/dns-load-generator created
==> Waiting for Job to start...
==> Measuring CoreDNS CPU usage for 60 seconds...
   [15:30:47] Cluster-wide CoreDNS CPU: 214m
   [15:30:53] Cluster-wide CoreDNS CPU: 216m
   [15:30:58] Cluster-wide CoreDNS CPU: 216m
   [15:31:04] Cluster-wide CoreDNS CPU: 220m
   [15:31:10] Cluster-wide CoreDNS CPU: 220m
   [15:31:16] Cluster-wide CoreDNS CPU: 220m
   [15:31:22] Cluster-wide CoreDNS CPU: 224m
   [15:31:28] Cluster-wide CoreDNS CPU: 224m
   [15:31:34] Cluster-wide CoreDNS CPU: 225m
   [15:31:40] Cluster-wide CoreDNS CPU: 224m
   [15:31:46] Cluster-wide CoreDNS CPU: 225m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 220m
==================================================

>>> Running Performance Test (EXTERNAL Queries)...
==================================================
   OpenShift CoreDNS CPU Benchmark
   Target Context: admin
   Target Cluster: https://api.ci-ln-t64rh1t-76ef8.aws-4.ci.openshift.org:6443
   Duration: 60s | Target QPS: 2000
==================================================
==> Cleaning up previous run...
namespace "dns-stress-test" deleted
==> Setting up test namespace: dns-stress-test
namespace/dns-stress-test created
==> Creating query payload (Type: external)...
configmap/dns-queries created
==> Launching dnsperf Job...
job.batch/dns-load-generator created
==> Waiting for Job to start...
==> Measuring CoreDNS CPU usage for 60 seconds...
   [15:32:09] Cluster-wide CoreDNS CPU: 225m
   [15:32:15] Cluster-wide CoreDNS CPU: 225m
   [15:32:21] Cluster-wide CoreDNS CPU: 228m
   [15:32:27] Cluster-wide CoreDNS CPU: 228m
   [15:32:33] Cluster-wide CoreDNS CPU: 228m
   [15:32:39] Cluster-wide CoreDNS CPU: 228m
   [15:32:45] Cluster-wide CoreDNS CPU: 228m
   [15:32:51] Cluster-wide CoreDNS CPU: 227m
   [15:32:57] Cluster-wide CoreDNS CPU: 227m
   [15:33:03] Cluster-wide CoreDNS CPU: 227m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 227m
==================================================

================================================================
 TEST COMPLETE
================================================================

!!! Restoring Cluster Operators !!!
Scaling up dns-operator...
Warning: spec.template.spec.nodeSelector[node-role.kubernetes.io/master]: use "node-role.kubernetes.io/control-plane" instead
deployment.apps/dns-operator scaled
Scaling up cluster-version-operator...
Warning: spec.template.spec.nodeSelector[node-role.kubernetes.io/master]: use "node-role.kubernetes.io/control-plane" instead
deployment.apps/cluster-version-operator scaled
Note: It may take a few minutes for the operators to revert CoreDNS version.
```

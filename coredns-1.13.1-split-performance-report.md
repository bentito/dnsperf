# CoreDNS 1.13.1 Split Query Performance Report

**Date:** December 9, 2025  
**Cluster:** OpenShift 4.19 (`openshift-4.19` context)  
**Test Method:** A/B Swap on identical hardware (Single Cluster) with Split Internal/External Queries  
**Tool:** `dnsperf` @ 2000 QPS

## Executive Summary

CoreDNS **1.13.1** demonstrated a **slight increase in CPU consumption** compared to the baseline version **1.11.3** across both internal and external query workloads.

| Version | Workload Type | Average CPU (mCores) | Delta |
| :--- | :--- | :--- | :--- |
| **1.11.3** (Baseline) | Internal (Cluster Local) | **283m** | - |
| **1.13.1** (Upgraded) | Internal (Cluster Local) | **296m** | **+13m (+4.6%)** |
| | | | |
| **1.11.3** (Baseline) | External (Upstream) | **282m** | - |
| **1.13.1** (Upgraded) | External (Upstream) | **303m** | **+21m (+7.4%)** |

## Conclusion

The upgraded version (1.13.1) consumed slightly more CPU resources than the baseline (1.11.3) in this specific test execution.
*   **Internal Queries:** +4.6% CPU usage.
*   **External Queries:** +7.4% CPU usage.

While the increase is relatively small (<10%), it stands in contrast to previous runs that showed improvements. This variability suggests environmental noise or specific overheads in the new version handling these request patterns.

---

## Appendix: Raw Execution Log

```text
$ ./dnsperf-swap-test.sh
################################################################
#  CoreDNS A/B Test on Single Cluster (openshift-4.19)  #
################################################################

================================================================
 PHASE 1: BASELINE (Existing Version)
================================================================

>>> Running Version Verification...
==================================================
   Checking CoreDNS Version
   Context: openshift-4.19
   Cluster: https://api.btofel-netedg-251209.devcluster.openshift.com:6443
==================================================
Querying binary version in pod: dns-default-4vsd6
--------------------------------------------------
CoreDNS-1.11.3
linux/amd64, go1.23.9 (Red Hat 1.23.9-1.el9_6) X:strictfipsruntime,
--------------------------------------------------

>>> Running Performance Test (INTERNAL Queries)...
==================================================
   OpenShift CoreDNS CPU Benchmark
   Target Context: openshift-4.19
   Target Cluster: https://api.btofel-netedg-251209.devcluster.openshift.com:6443
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
   [17:24:31] Cluster-wide CoreDNS CPU: 286m
   [17:24:36] Cluster-wide CoreDNS CPU: 286m
   [17:24:42] Cluster-wide CoreDNS CPU: 286m
   [17:24:47] Cluster-wide CoreDNS CPU: 284m
   [17:24:53] Cluster-wide CoreDNS CPU: 284m
   [17:24:59] Cluster-wide CoreDNS CPU: 284m
   [17:25:04] Cluster-wide CoreDNS CPU: 284m
   [17:25:10] Cluster-wide CoreDNS CPU: 284m
   [17:25:15] Cluster-wide CoreDNS CPU: 281m
   [17:25:21] Cluster-wide CoreDNS CPU: 281m
   [17:25:27] Cluster-wide CoreDNS CPU: 281m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 283m
==================================================

>>> Running Performance Test (EXTERNAL Queries)...
==================================================
   OpenShift CoreDNS CPU Benchmark
   Target Context: openshift-4.19
   Target Cluster: https://api.btofel-netedg-251209.devcluster.openshift.com:6443
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
   [17:25:48] Cluster-wide CoreDNS CPU: 282m
   [17:25:53] Cluster-wide CoreDNS CPU: 282m
   [17:25:59] Cluster-wide CoreDNS CPU: 283m
   [17:26:05] Cluster-wide CoreDNS CPU: 283m
   [17:26:10] Cluster-wide CoreDNS CPU: 283m
   [17:26:16] Cluster-wide CoreDNS CPU: 282m
   [17:26:21] Cluster-wide CoreDNS CPU: 282m
   [17:26:27] Cluster-wide CoreDNS CPU: 282m
   [17:26:32] Cluster-wide CoreDNS CPU: 282m
   [17:26:38] Cluster-wide CoreDNS CPU: 282m
   [17:26:44] Cluster-wide CoreDNS CPU: 281m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 282m
==================================================

================================================================
 PHASE 2: SWAPPING IMAGE TO 1.13.1
 Target: quay.io/openshift-release-dev/ocp-v4.0-art-dev @sha256:18504c088c4b54069cf75c2d7d2dc9dd3d0607c4ac9b6a3f6a302bd80f0890bc
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
   Context: openshift-4.19
   Cluster: https://api.btofel-netedg-251209.devcluster.openshift.com:6443
==================================================
Querying binary version in pod: dns-default-78mwx
--------------------------------------------------
CoreDNS-1.13.1
linux/amd64, go1.24.6 (Red Hat 1.24.6-1.el9_6) X:strictfipsruntime,
--------------------------------------------------

>>> Running Performance Test (INTERNAL Queries)...
==================================================
   OpenShift CoreDNS CPU Benchmark
   Target Context: openshift-4.19
   Target Cluster: https://api.btofel-netedg-251209.devcluster.openshift.com:6443
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
   [17:29:32] Cluster-wide CoreDNS CPU: 292m
   [17:29:37] Cluster-wide CoreDNS CPU: 292m
   [17:29:43] Cluster-wide CoreDNS CPU: 297m
   [17:29:48] Cluster-wide CoreDNS CPU: 297m
   [17:29:54] Cluster-wide CoreDNS CPU: 297m
   [17:29:59] Cluster-wide CoreDNS CPU: 297m
   [17:30:05] Cluster-wide CoreDNS CPU: 297m
   [17:30:11] Cluster-wide CoreDNS CPU: 297m
   [17:30:16] Cluster-wide CoreDNS CPU: 298m
   [17:30:22] Cluster-wide CoreDNS CPU: 298m
   [17:30:27] Cluster-wide CoreDNS CPU: 298m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 296m
==================================================

>>> Running Performance Test (EXTERNAL Queries)...
==================================================
   OpenShift CoreDNS CPU Benchmark
   Target Context: openshift-4.19
   Target Cluster: https://api.btofel-netedg-251209.devcluster.openshift.com:6443
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
   [17:30:49] Cluster-wide CoreDNS CPU: 303m
   [17:30:54] Cluster-wide CoreDNS CPU: 303m
   [17:31:00] Cluster-wide CoreDNS CPU: 302m
   [17:31:05] Cluster-wide CoreDNS CPU: 302m
   [17:31:11] Cluster-wide CoreDNS CPU: 302m
   [17:31:16] Cluster-wide CoreDNS CPU: 304m
   [17:31:22] Cluster-wide CoreDNS CPU: 304m
   [17:31:27] Cluster-wide CoreDNS CPU: 304m
   [17:31:33] Cluster-wide CoreDNS CPU: 304m
   [17:31:39] Cluster-wide CoreDNS CPU: 304m
   [17:31:44] Cluster-wide CoreDNS CPU: 307m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 303m
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

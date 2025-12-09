# CoreDNS 1.13.1 Performance Regression Test Report

**Date:** December 9, 2025  
**Cluster:** OpenShift 4.19 (`openshift-4.19` context)  
**Test Method:** A/B Swap on identical hardware (Single Cluster)  
**Tool:** `dnsperf` @ 2000 QPS

## Executive Summary

CoreDNS **1.13.1** demonstrated a **~13.4% reduction in CPU consumption** compared to the baseline version **1.11.3** under identical load conditions.

| Version | Go Version | Average CPU (mCores) | Delta |
| :--- | :--- | :--- | :--- |
| **1.11.3** (Baseline) | go1.23.9 | **239m** | - |
| **1.13.1** (Upgraded) | go1.24.6 | **207m** | **-32m (-13.4%)** |

## Conclusion

The upgraded version (1.13.1) is more efficient than the current baseline on OpenShift 4.19. No performance regression was observed; instead, a significant performance improvement was recorded.

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
Querying binary version in pod: dns-default-7br68
--------------------------------------------------
CoreDNS-1.11.3
linux/amd64, go1.23.9 (Red Hat 1.23.9-1.el9_6) X:strictfipsruntime,
--------------------------------------------------

>>> Running Performance Test...
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
==> Creating query payload...
configmap/dns-queries created
==> Launching dnsperf Job...
job.batch/dns-load-generator created
==> Waiting for Job to start...
==> Measuring CoreDNS CPU usage for 60 seconds...
   [15:39:35] Cluster-wide CoreDNS CPU: 236m
   [15:39:41] Cluster-wide CoreDNS CPU: 236m
   [15:39:46] Cluster-wide CoreDNS CPU: 239m
   [15:39:52] Cluster-wide CoreDNS CPU: 239m
   [15:39:57] Cluster-wide CoreDNS CPU: 240m
   [15:40:03] Cluster-wide CoreDNS CPU: 240m
   [15:40:09] Cluster-wide CoreDNS CPU: 240m
   [15:40:14] Cluster-wide CoreDNS CPU: 241m
   [15:40:20] Cluster-wide CoreDNS CPU: 241m
   [15:40:25] Cluster-wide CoreDNS CPU: 241m
   [15:40:31] Cluster-wide CoreDNS CPU: 241m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 239m
==================================================

================================================================
 PHASE 2: SWAPPING IMAGE TO 1.13.1
 Target: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:18504c088c4b54069cf75c2d7d2dc9dd3d0607c4ac9b6a3f6a302bd80f0890bc
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
Querying binary version in pod: dns-default-4wtm7
--------------------------------------------------
CoreDNS-1.13.1
linux/amd64, go1.24.6 (Red Hat 1.24.6-1.el9_6) X:strictfipsruntime,
--------------------------------------------------

>>> Running Performance Test...
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
==> Creating query payload...
configmap/dns-queries created
==> Launching dnsperf Job...
job.batch/dns-load-generator created
==> Waiting for Job to start...
==> Measuring CoreDNS CPU usage for 60 seconds...
   [15:43:19] Cluster-wide CoreDNS CPU: 203m
   [15:43:24] Cluster-wide CoreDNS CPU: 203m
   [15:43:30] Cluster-wide CoreDNS CPU: 207m
   [15:43:35] Cluster-wide CoreDNS CPU: 207m
   [15:43:41] Cluster-wide CoreDNS CPU: 207m
   [15:43:46] Cluster-wide CoreDNS CPU: 208m
   [15:43:52] Cluster-wide CoreDNS CPU: 208m
   [15:43:57] Cluster-wide CoreDNS CPU: 208m
   [15:44:03] Cluster-wide CoreDNS CPU: 209m
   [15:44:08] Cluster-wide CoreDNS CPU: 209m
   [15:44:14] Cluster-wide CoreDNS CPU: 212m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 207m
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

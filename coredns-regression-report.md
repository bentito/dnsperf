# CoreDNS Performance Comparison: OpenShift 4.19 vs 4.21

## Executive Summary
CoreDNS 1.13.1 (OCP 4.21) demonstrates a **significant CPU efficiency regression** compared to CoreDNS 1.11.3 (OCP 4.19). despite running on ~25% faster hardware, the 4.21 instance consumed **20% more raw CPU**.

When normalized for hardware performance, **CoreDNS 1.13.1 is approximately 50% less efficient** than 1.11.3 for this workload.

## Test Environment
| Metric | OpenShift 4.19 (Baseline) | OpenShift 4.21 (Target) |
| :--- | :--- | :--- |
| **Cluster Provider** | AWS (m6i.xlarge) | GCP (e2-custom) |
| **CPU Model** | Intel Xeon Platinum 8375C | AMD EPYC 7B12 |
| **CoreDNS Version** | 1.11.3 | 1.13.1 |
| **Go Version** | 1.23.9 | 1.24.6 |
| **Hardware Speed** | 1069 events/sec | 1342 events/sec (**+25.5%**) |

## Results
| Metric | 4.19 Actual | 4.21 Actual | 4.19 Normalized* | Delta (Normalized) |
| :--- | :--- | :--- | :--- | :--- |
| **Avg CPU Usage** | 300m | **360m** | ~239m | **+50.6%** |

*\*Normalized 4.19 value projects what usage would be on the faster 4.21 hardware (300m / 1.255).*

---

## Appendix: Raw Output

### 1. DNS Performance & Version Check (4.21)
```
dnsperf  $ ./dnsperf.sh --context=openshift-4.21
...
   [14:21:32] Cluster-wide CoreDNS CPU: 360m
   ...
   [14:22:28] Cluster-wide CoreDNS CPU: 361m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 360m
==================================================

dnsperf  $ ./verify-coredns-version.sh --context=openshift-4.21
...
CoreDNS-1.13.1
linux/amd64, go1.24.6 (Red Hat 1.24.6-1.el9_6) X:strictfipsruntime,
```

### 2. DNS Performance & Version Check (4.19)
```
dnsperf  $ ./dnsperf.sh --context=openshift-4.19
...
   [14:22:55] Cluster-wide CoreDNS CPU: 300m
   ...
   [14:23:51] Cluster-wide CoreDNS CPU: 300m
==================================================
   RESULTS
==================================================
   Average Cluster-wide CoreDNS CPU: 300m
==================================================

dnsperf  $ ./verify-coredns-version.sh --context=openshift-4.19
...
CoreDNS-1.11.3
linux/amd64, go1.23.9 (Red Hat 1.23.9-1.el9_6) X:strictfipsruntime,
```

### 3. Hardware Baseline (Sysbench)
```
dnsperf  $ ./cluster-cpu-baseline.sh --context=openshift-4.21
...
Node: ci-ln-cdq4bc2-72292-qlkcr-worker-a-5hg87
Instance Type: e2-custom-6-16384
--- CPU Model ---
AMD EPYC 7B12
--- Running Sysbench CPU Test ---
CPU speed:
    events per second:  1341.92

dnsperf  $ ./cluster-cpu-baseline.sh --context=openshift-4.19
...
Node: ip-10-0-25-37.ec2.internal
Instance Type: m6i.xlarge
--- CPU Model ---
Intel(R) Xeon(R) Platinum 8375C CPU @ 2.90GHz
--- Running Sysbench CPU Test ---
CPU speed:
    events per second:  1069.24
```

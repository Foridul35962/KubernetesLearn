# Kubernetes Metrics Server

## Overview

Metrics Server collects CPU and memory usage metrics from Kubernetes Nodes and Pods.

These metrics can be accessed using `kubectl top` and are used by Horizontal Pod Autoscaler (HPA) for resource-based autoscaling.

## Prerequisites

- A running Kubernetes cluster (Kind, Minikube, or another cluster)
- `kubectl` installed and configured
- Access to the cluster

## Install Metrics Server

Run the installation script:

```bash
chmod +x install-metrics-server.sh
./install-metrics-server.sh
```

The script checks whether `kubectl` is installed and the cluster is reachable, then applies the official Metrics Server manifest.

- Edit the Metrics Server Deployment
```bash
kubectl -n kube-system edit deployment metrics-server
```
- Add the security bypass to deployment under `container.args`
```bash
- --kubelet-insecure-tls
- --kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP
```
- Restart the deployment
```bash
kubectl -n kube-system rollout restart deployment metrics-server
```
- Verify if the metrics server is running
```bash
kubectl get pods -n kube-system
kubectl top nodes
```

Inspect the error before changing configuration. Do not disable TLS verification unless the logs indicate it is necessary for the local Kind environment.

## References

- [Metrics Server GitHub Repository](https://github.com/kubernetes-sigs/metrics-server)
- [Metrics Server Installation](https://github.com/kubernetes-sigs/metrics-server#installation)
- [Kubernetes Resource Metrics Pipeline](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)

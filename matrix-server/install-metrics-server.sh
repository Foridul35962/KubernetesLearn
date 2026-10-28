#!/usr/bin/env bash

set -e

echo "======================================"
echo " Installing Kubernetes Metrics Server"
echo "======================================"

if ! command -v kubectl >/dev/null 2>&1; then
    echo "ERROR: kubectl is not installed."
    exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to Kubernetes cluster."
    echo "Check your current kubectl context."
    exit 1
fi

echo
echo "Current Kubernetes context:"
kubectl config current-context

echo
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo
echo "Kubernetes Metrics Server installed successfully!"


# Edit the Metrics Server Deployment
# kubectl -n kube-system edit deployment metrics-server
# Add the security bypass to deployment under container.args
# - --kubelet-insecure-tls
# - --kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP
# Restart the deployment
# kubectl -n kube-system rollout restart deployment metrics-server
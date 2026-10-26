# single line command:
# kind create cluster --name forid-cluster --config kind-cluster.yaml


#!/bin/bash

set -e

echo "🚀 Creating Kubernetes cluster..."

kind create cluster \
  --name forid-cluster \
  --config kind-cluster.yaml

echo "📦 Creating namespace..."

kubectl create namespace development \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Cluster and namespace are ready!"

kubectl get nodes
kubectl get namespaces

# after finished the project
# sudo docker stop $(sudo docker ps -q --filter "label=io.x-k8s.kind.cluster=forid-cluster")

# before start project
# sudo docker start $(sudo docker ps -aq --filter "label=io.x-k8s.kind.cluster=forid-cluster")
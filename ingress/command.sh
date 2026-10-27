
#!/bin/bash

set -e

echo "Installing NGINX Ingress Controller..."

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Checking Ingress Controller status..."

kubectl get pods -n ingress-nginx

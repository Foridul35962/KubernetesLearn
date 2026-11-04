# KubernetesLearn

My Kubernetes learning journey with Docker, Kind, kubectl, YAML manifests, deployments, services, and hands-on projects.

This repository is my personal lab notebook. Every folder covers one Kubernetes concept with small, runnable manifests and scripts, and the last few folders put those concepts together in real mini projects. Everything runs locally on a [Kind](https://kind.sigs.k8s.io/) cluster (Kubernetes in Docker), so no cloud account is needed.

## Table of Contents

- [What I Learned](#what-i-learned)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Suggested Learning Order](#suggested-learning-order)
- [Hands-on Projects](#hands-on-projects)
- [Useful Commands](#useful-commands)
- [Notes](#notes)
- [License](#license)

## What I Learned

| Topic | Folder | Summary |
| --- | --- | --- |
| Installation | `installation/` | One script that installs Docker, Kind, and kubectl on Ubuntu/Debian (amd64 and arm64) |
| Cluster | `cluster/` | A multi-node Kind cluster: 1 control-plane and 3 workers |
| Namespaces | `namespaces/` | Isolating resources with the `development` namespace |
| Pods | `pods/` | The smallest deployable unit: a single nginx Pod |
| Deployments | `deployment/` | Replicas, resource requests/limits, and volume mounts |
| Services | `service/` | Exposing Pods inside the cluster with a ClusterIP Service |
| Ingress | `ingress/` | Path-based routing with the NGINX Ingress Controller |
| Volumes | `volumes/` | PersistentVolume (PV) and PersistentVolumeClaim (PVC) |
| Metrics Server | `metrics-server/` | Collecting CPU/memory metrics for `kubectl top` and autoscaling |
| Autoscaling | `hpa/` | Horizontal Pod Autoscaler with a load-generation script |
| StatefulSets | `statefulSet/` | MySQL with a ConfigMap, Secret, headless Service, and per-Pod storage |
| Dashboard | `dashboard/` | Kubernetes Dashboard with an admin ServiceAccount and token login |
| Monitoring | `monitoring/` | Prometheus and Grafana installed with Helm (`kube-prometheus-stack`) |
| Projects | `project/`, `chatApp/` | Full applications deployed end to end |

## Tech Stack

- **Docker** for container runtime and for hosting the Kind nodes
- **Kind** for local multi-node Kubernetes clusters
- **kubectl** for talking to the cluster
- **YAML manifests** for declarative configuration
- **Helm** for installing Prometheus and Grafana
- **Bash** for helper and setup scripts

## Repository Structure

```text
KubernetesLearn/
├── installation/      # install.sh: Docker + Kind + kubectl
├── cluster/           # kind-cluster.yaml, command.sh
├── namespaces/        # create-namespaces.yaml
├── pods/              # create-pods.yaml
├── deployment/        # create-deployment.yaml
├── service/           # create-service.yaml
├── ingress/           # command.sh, create-ingress.yaml
├── volumes/           # pv.yaml, pvc.yaml
├── metrics-server/     # Metrics Server install script + README
├── hpa/               # create-hpa.yaml, create-load.sh
├── statefulSet/       # configmap, secret, service, StatefulSet (MySQL)
├── dashboard/         # Kubernetes Dashboard setup + README
├── monitoring/        # Prometheus + Grafana via Helm + README
├── project/           # Notes app (Deployment + Service)
├── chatApp/           # 3-tier chat app (React + Node.js + MongoDB)
├── LICENSE
└── README.md
```

## Getting Started

### Prerequisites

- A Linux machine (the install script targets Ubuntu/Debian with `apt`)
- `sudo` access
- Internet connection to pull images and manifests

### 1. Install the tools

```bash
cd installation
chmod +x install.sh
./install.sh
```

The script installs Docker, Kind, and kubectl only if they are missing, then prints their versions. Log out and back in afterwards so the Docker group permission takes effect.

### 2. Create the cluster

```bash
cd cluster
kind create cluster --name forid-cluster --config kind-cluster.yaml
kubectl get nodes
```

`command.sh` does the same thing and also creates the `development` namespace.

### 3. Apply any manifest

```bash
kubectl apply -f <folder>/<file>.yaml
kubectl get all -n development
```

### 4. Stop and start the cluster without deleting it

Kind clusters are Docker containers, so you can pause them to save resources:

```bash
# stop
docker stop $(docker ps -q --filter "label=io.x-k8s.kind.cluster=forid-cluster")

# start again
docker start $(docker ps -aq --filter "label=io.x-k8s.kind.cluster=forid-cluster")
```

### 5. Clean up

```bash
kind delete cluster --name forid-cluster
```

## Suggested Learning Order

Follow the folders in this order, because later ones depend on earlier ones:

1. `installation/` → `cluster/` → `namespaces/`
2. `volumes/` (the Deployment mounts the `forid-pvc` claim, so apply `pv.yaml` and `pvc.yaml` first)
3. `pods/` → `deployment/` → `service/`
4. `ingress/` (run `command.sh` first to install the controller, then apply `create-ingress.yaml`)
5. `metrics-server/` → `hpa/`
6. `statefulSet/`
7. `dashboard/` and `monitoring/`
8. `project/` and `chatApp/`

### Ingress

```bash
cd ingress
bash command.sh                          # installs the NGINX Ingress Controller for Kind
kubectl apply -f create-ingress.yaml
```

Routes defined in `create-ingress.yaml`:

| Path | Backend Service | Port |
| --- | --- | --- |
| `/nginx` | `nginx-service` | 8080 |
| `/` | `note-service` | 8000 |

### Autoscaling (HPA)

The HPA needs Metrics Server to read CPU usage.

```bash
# 1. Install Metrics Server (see metrics-server/README.md for the Kind-specific TLS fix)
cd metrics-server && bash install-metrics-server.sh

# 2. Apply the autoscaler
kubectl apply -f ../hpa/create-hpa.yaml

# 3. Expose the nginx Service locally, then generate load
kubectl port-forward svc/nginx-service 8080:8080 -n development
bash ../hpa/create-load.sh

# 4. Watch the replicas scale between 1 and 3
kubectl get hpa -n development -w
```

### StatefulSet (MySQL)

The manifests use a `mysql` namespace, so create it first:

```bash
kubectl create namespace mysql
kubectl apply -f statefulSet/
kubectl get pods -n mysql
```

### Dashboard

```bash
cd dashboard
bash config.sh                                   # deploys the Dashboard
kubectl apply -f create-dashboard.yaml           # admin ServiceAccount + binding
kubectl -n kubernetes-dashboard create token admin-user
kubectl proxy
```

Then open the Dashboard URL from `dashboard/README.md` and log in with the token.

### Monitoring

See [`monitoring/README.md`](monitoring/README.md) for the full Helm walkthrough, port-forward commands, troubleshooting, and cleanup.

## Hands-on Projects

### Notes App (`project/`)

A single-container web app exposed through a ClusterIP Service and reachable via the Ingress `/` path.

- Deployment `note-dev` with resource requests and limits (port 8000)
- Service `note-service` in the `development` namespace

```bash
kubectl apply -f project/config.yaml
```

### Chat App (`chatApp/`)

A three-tier application running in its own `chatapp` namespace.

| Tier | Resource | Port |
| --- | --- | --- |
| Frontend | Deployment + Service (`frontend-service`) | 80 |
| Backend | Deployment + Service (`backend-service`) with a JWT secret | 5001 |
| Database | MongoDB StatefulSet + headless Service with a 1Gi volume | 27017 |

```bash
kubectl apply -f chatApp/namespace.yaml
kubectl apply -f chatApp/mongodb.yaml
kubectl apply -f chatApp/backend.yaml
kubectl apply -f chatApp/frontend.yaml
kubectl get pods -n chatapp
```

The Notes and Chat apps use public container images from `trainwithshubham` on Docker Hub.

## Useful Commands

```bash
kubectl get nodes                          # cluster nodes
kubectl get pods -A                        # all Pods in every namespace
kubectl get all -n <namespace>             # everything in a namespace
kubectl describe pod <pod> -n <namespace>  # events and details for debugging
kubectl logs <pod> -n <namespace>          # container logs
kubectl exec -it <pod> -n <namespace> -- sh
kubectl top nodes                          # needs Metrics Server
kubectl top pods -n <namespace>
kubectl delete -f <file>.yaml              # remove what a manifest created
```

## Notes

- This is a **learning repository**. Passwords and tokens in the manifests are demo values for a local cluster only. For anything real, use proper secret management and never commit credentials.
- Some manifests use the `latest` image tag for simplicity. Pin versions in real deployments.
- The Kind cluster in `cluster/kind-cluster.yaml` has 4 nodes (1 control-plane, 3 workers), so it needs a reasonable amount of RAM.
- Kind clusters are lost if Docker's data is removed. Recreate the cluster and re-apply the manifests when that happens.

## License

This project is licensed under the [MIT License](LICENSE).

---

Built while learning Kubernetes by [Foridul](https://github.com/Foridul35962). If you are learning too, feel free to fork it and experiment.

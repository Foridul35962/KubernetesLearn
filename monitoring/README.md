# Grafana + Prometheus Monitoring on Kubernetes (Kind)

This README documents the commands used to install and access Grafana
and Prometheus on a Kind Kubernetes cluster using Helm. It also explains
what each command does, how to retrieve the Grafana admin password, and
how to troubleshoot the issues encountered during setup.

> **Environment:** Zorin OS / Ubuntu-based Linux, Kind Kubernetes
> cluster, `kubectl`, and the project directory
> `KubernetesLearn/monitoring`.
>
> **Important:** This setup installs the monitoring stack in the
> `monitoring` namespace. Grafana's admin password is stored in a
> Kubernetes Secret. Do not commit the password to GitHub.

------------------------------------------------------------------------

## 1. Navigate to the monitoring directory

``` bash
cd ~/Projects/KubernetesLearn/monitoring
```

If your project is stored somewhere else, update the path accordingly.

## 2. Install Helm

Helm is a Kubernetes package manager. It allows you to install
applications and complete application stacks using Helm charts.

Download the Helm installation script:

``` bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
```

Make the script executable:

``` bash
chmod +x get_helm.sh
```

Run the installer:

``` bash
./get_helm.sh
```

The installer may ask for your `sudo` password because it installs Helm
into `/usr/local/bin`.

Verify the installation:

``` bash
helm version
```

> **Note:** If the download is interrupted, `get_helm.sh` may not exist.
> Run the `curl` command again before running `chmod` or executing the
> script.

## 3. Add the Prometheus Community Helm repository

The `kube-prometheus-stack` chart is maintained in the Prometheus
Community Helm repository.

Add the repository:

``` bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

List configured Helm repositories:

``` bash
helm repo list
```

Update the local repository metadata:

``` bash
helm repo update
```

## 4. Create the monitoring namespace

Create a dedicated namespace for monitoring resources:

``` bash
kubectl create namespace monitoring
```

If the namespace already exists, Kubernetes may return an
`AlreadyExists` message. In that case, you can continue without creating
it again.

## 5. Install kube-prometheus-stack

The following command installs the complete monitoring stack, including
Prometheus, Grafana, Alertmanager, Node Exporter, kube-state-metrics,
and the Prometheus Operator.

``` bash
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.service.nodePort=30000 \
  --set grafana.service.nodePort=31000 \
  --set grafana.service.type=NodePort \
  --set prometheus.service.type=NodePort
```

Command breakdown:

-   `prometheus-stack` --- the Helm release name.
-   `prometheus-community/kube-prometheus-stack` --- the chart being
    installed.
-   `--namespace monitoring` --- installs the resources in the
    `monitoring` namespace.
-   `prometheus.service.type=NodePort` --- configures the Prometheus
    Service as a NodePort Service.
-   `prometheus.service.nodePort=30000` --- assigns NodePort `30000` to
    Prometheus.
-   `grafana.service.type=NodePort` --- configures the Grafana Service
    as a NodePort Service.
-   `grafana.service.nodePort=31000` --- assigns NodePort `31000` to
    Grafana.

When the installation succeeds, Helm reports `STATUS: deployed`.

> **Kind note:** Configuring a NodePort does not always make that port
> directly accessible from the host machine. For local access, this
> guide uses `kubectl port-forward` in the next section.

## 6. Access Grafana and Prometheus

### 6.1 Access Grafana

The Grafana Kubernetes Service listens on port `80`, and forwards
traffic to port `3000` inside the Grafana container.

Run:

``` bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

Open this address in your browser:

``` text
http://localhost:3000
```

Keep the terminal running while you use Grafana. Closing the terminal or
stopping the command terminates the port-forward.

### 6.2 Access Prometheus

Open a second terminal and run:

``` bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
```

Open Prometheus in your browser:

``` text
http://localhost:9090
```

This port-forward also remains active only while its command is running.

### 6.3 Run port-forward in the background (optional)

You can append `&` to run a port-forward process in the background:

``` bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80 &
```

``` bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090 &
```

List background jobs:

``` bash
jobs -l
```

Stop a background job using its job number. For example, to stop job
number 1:

``` bash
kill %1
```

Use the job number shown by `jobs -l`. To stop a foreground
port-forward, press `Ctrl + C`.

## 7. Retrieve Grafana login credentials

The default Grafana username is:

``` text
admin
```

The admin password is generated during installation and stored in a
Kubernetes Secret. Retrieve and decode it with:

``` bash
kubectl get secret prometheus-stack-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 --decode
```

To print a newline after the password:

``` bash
kubectl get secret prometheus-stack-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 --decode
echo
```

Use these credentials on the Grafana login page:

-   **Username:** `admin`
-   **Password:** the output of the command above.

### Why is Base64 decoding required?

Kubernetes Secret values under `.data` are Base64-encoded. The
`base64 --decode` command converts the encoded value into readable text.

> **Security warning:** Base64 is an encoding format, not encryption. Do
> not publish the decoded password in a README, screenshot, or public
> GitHub repository. This README intentionally does not contain the
> actual password.

## 8. Troubleshooting

### 8.1 `get_helm.sh: No such file or directory`

The installer script may not have downloaded successfully. Download it
again:

``` bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
```

Then make it executable and run it:

``` bash
chmod +x get_helm.sh
./get_helm.sh
```

### 8.2 Permission denied when forwarding local port 80

You may encounter an error similar to:

``` text
bind: permission denied
```

On Linux, binding to ports below `1024` generally requires elevated
privileges. Instead of forwarding Grafana to local port `80`, use an
unprivileged local port such as `3000`:

``` bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

Then open `http://localhost:3000`. This avoids the need to run `kubectl`
with `sudo`.

### 8.3 `kubectl` command typo

The correct command is `kubectl`, not `kubeclt`.

### 8.4 Pods take time to become ready

Immediately after installation, some Pods may temporarily show states
such as `ContainerCreating` or `PodInitializing`. This can happen while
container images are being pulled and containers are starting. Wait for
the components to become ready before opening the dashboards.

### 8.5 Local port is already in use

If another process is already using local port `3000`, choose a
different local port. For example:

``` bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3001:80
```

Then open:

``` text
http://localhost:3001
```

## 9. Complete setup command sequence

Use this sequence when setting up the monitoring stack from scratch. If
Helm is already installed, skip the Helm installation commands.

``` bash
# Navigate to the monitoring directory
cd ~/Projects/KubernetesLearn/monitoring

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod +x get_helm.sh
./get_helm.sh

# Add and update the Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create the namespace (skip if it already exists)
kubectl create namespace monitoring

# Install Prometheus and Grafana
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.service.nodePort=30000 \
  --set grafana.service.nodePort=31000 \
  --set grafana.service.type=NodePort \
  --set prometheus.service.type=NodePort
```

After installation, use two separate terminals.

**Terminal 1 --- Grafana**

``` bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

Open: `http://localhost:3000`

**Terminal 2 --- Prometheus**

``` bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
```

Open: `http://localhost:9090`

**Retrieve the Grafana password**

``` bash
kubectl get secret prometheus-stack-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 --decode
echo
```

## 10. Uninstall the monitoring stack

To uninstall the Helm release:

``` bash
helm uninstall prometheus-stack --namespace monitoring
```

This removes the resources managed by that Helm release. If you also
want to delete the namespace, run:

``` bash
kubectl delete namespace monitoring
```

> **Warning:** Deleting the namespace also deletes any other resources
> inside it. Only do this if you are sure you no longer need them.

## 11. Quick reference

  Item                             Value
  -------------------------------- ----------------------------------------------
  Helm release                     `prometheus-stack`
  Helm chart                       `prometheus-community/kube-prometheus-stack`
  Namespace                        `monitoring`
  Grafana username                 `admin`
  Grafana browser URL              `http://localhost:3000`
  Prometheus browser URL           `http://localhost:9090`
  Configured Grafana NodePort      `31000`
  Configured Prometheus NodePort   `30000`
  Grafana password                 Retrieve from the Kubernetes Secret

## 12. Important reminders

-   This setup installs the complete kube-prometheus-stack, not Grafana
    alone.
-   Prometheus is configured as the data source for Grafana by the
    chart.
-   Keep the Grafana and Prometheus port-forward commands running while
    accessing their web interfaces.
-   The configured NodePorts are `31000` for Grafana and `30000` for
    Prometheus. This guide uses port-forwarding for reliable local
    access from the Kind environment.
-   Never commit the Grafana admin password or other secrets to GitHub.

#!/bin/bash
#install for linux

set -e
set -o pipefail

echo "🚀 Starting installation of Docker, Kind, and kubectl..."

# ----------------------------
# 1. Install Docker
# ----------------------------
if ! command -v docker &>/dev/null; then
  echo "📦 Installing Docker..."

  sudo apt-get update -y
  sudo apt-get install -y docker.io

  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"

  echo "✅ Docker installed and user added to docker group."
  echo "⚠️ Log out and log in again to apply Docker group permissions."
else
  echo "✅ Docker is already installed."
  sudo systemctl enable --now docker
fi

# ----------------------------
# 2. Install Kind (based on architecture)
# ----------------------------
if ! command -v kind &>/dev/null; then
  echo "📦 Installing Kind..."

  ARCH=$(uname -m)

  if [ "$ARCH" = "x86_64" ]; then
    KIND_ARCH="amd64"
  elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    KIND_ARCH="arm64"
  else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
  fi

  curl -fLo ./kind \
    "https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-${KIND_ARCH}"

  chmod +x ./kind
  sudo install -o root -g root -m 0755 ./kind /usr/local/bin/kind
  rm ./kind

  echo "✅ Kind installed successfully."
else
  echo "✅ Kind is already installed."
fi

# ----------------------------
# 3. Install kubectl (based on architecture)
# ----------------------------

if ! command -v kubectl &>/dev/null; then
  echo "📦 Installing kubectl (latest stable version)..."

  ARCH=$(uname -m)
  VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)

  echo "✅ Version found: $VERSION"
  echo "⏳ Downloading kubectl. Please wait..."

  if [ "$ARCH" = "x86_64" ]; then
    KUBECTL_ARCH="amd64"
  elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    KUBECTL_ARCH="arm64"
  else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
  fi

  curl -fLo ./kubectl \
    "https://dl.k8s.io/release/${VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"

  sudo install -o root -g root -m 0755 ./kubectl /usr/local/bin/kubectl
  rm ./kubectl

  echo "✅ kubectl installed successfully."
else
  echo "✅ kubectl is already installed."
fi

# ----------------------------
# 4. Confirm Versions
# ----------------------------

echo
echo "🔍 Installed Versions:"

docker --version
kind --version
kubectl version --client --output=yaml

echo
echo "🎉 Docker, Kind, and kubectl installation complete!"
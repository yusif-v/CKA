#!/usr/bin/env bash
# =============================================================
#  CKA Lab — Linux (Debian/Ubuntu/Mint/Pop!_OS) Setup Script
#  Installs: Docker Engine · kind · kubectl · helm
# =============================================================

set -euo pipefail

ARCH="${CKA_ARCH:-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')}"
KIND_CLUSTER_NAME="cka-lab"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────────────
log_step()  { echo ""; echo -e "${CYAN}${BOLD}▶ $1${NC}"; }
log_ok()    { echo -e "  ${GREEN}✔${NC} $1"; }
log_warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "  ${RED}✘${NC} $1"; exit 1; }
log_info()  { echo -e "  ${DIM}→ $1${NC}"; }

check_command() {
  if command -v "$1" &>/dev/null; then
    log_ok "$1 already installed: $(command -v "$1")"
    return 0
  fi
  return 1
}

# Determine sudo usage
SUDO=""
if [ "$EUID" -ne 0 ]; then
  if command -v sudo &>/dev/null; then
    SUDO="sudo"
  else
    log_error "Not running as root and 'sudo' not found. Please run as root or install sudo."
  fi
fi

# Detect distro info
DISTRO_NAME="Unknown"
DISTRO_VERSION="Unknown"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO_NAME="${PRETTY_NAME:-$ID}"
  DISTRO_VERSION="${VERSION_ID:-}"
fi

# ── Banner ───────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  Linux (Debian-based) Installer${NC}"
echo -e "  Distro: ${BOLD}$DISTRO_NAME${NC}"
echo -e "  Architecture: ${BOLD}$ARCH${NC}"
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 1 — System update & prerequisites
# ══════════════════════════════════════════════════════════════
log_step "Step 1/6 — System update & prerequisites"

log_info "Updating package index..."
$SUDO apt-get update -qq

log_info "Installing prerequisites..."
$SUDO apt-get install -y -qq \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common \
  git \
  wget \
  jq

log_ok "Prerequisites installed"

# ══════════════════════════════════════════════════════════════
# STEP 2 — Docker Engine
# ══════════════════════════════════════════════════════════════
log_step "Step 2/6 — Docker Engine"

if check_command docker; then
  if ! docker info &>/dev/null; then
    log_warn "Docker installed but daemon not running. Starting..."
    $SUDO systemctl enable docker --quiet
    $SUDO systemctl start docker
  fi
  log_ok "Docker daemon is running"
else
  log_info "Adding Docker's official GPG key..."
  $SUDO install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

  log_info "Adding Docker repository..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

  log_info "Installing Docker Engine..."
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  log_info "Enabling and starting Docker service..."
  $SUDO systemctl enable docker --quiet
  $SUDO systemctl start docker

  # Add current user to docker group (avoids needing sudo for docker)
  CURRENT_USER="${SUDO_USER:-$USER}"
  if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    $SUDO usermod -aG docker "$CURRENT_USER"
    log_warn "User '$CURRENT_USER' added to 'docker' group."
    log_warn "You may need to log out and back in for this to take effect."
    log_warn "For this session, using: newgrp docker (or sudo docker ...)"
    # Apply group without logout for this session
    exec sg docker "$0" || true
  fi

  log_ok "Docker Engine installed and running"
fi

DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
log_info "Docker version: $DOCKER_VERSION"

# ══════════════════════════════════════════════════════════════
# STEP 3 — kind
# ══════════════════════════════════════════════════════════════
log_step "Step 3/6 — kind (Kubernetes in Docker)"

if check_command kind; then
  log_info "kind version: $(kind version)"
else
  KIND_ARCH="$ARCH"
  log_info "Downloading kind binary for linux/$KIND_ARCH..."
  KIND_URL="https://kind.sigs.k8s.io/dl/latest/kind-linux-${KIND_ARCH}"
  curl -fsSL "$KIND_URL" -o /tmp/kind
  $SUDO install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
  rm -f /tmp/kind
  log_ok "kind installed: $(kind version)"
fi

# ══════════════════════════════════════════════════════════════
# STEP 4 — kubectl
# ══════════════════════════════════════════════════════════════
log_step "Step 4/6 — kubectl"

if check_command kubectl; then
  log_info "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  log_info "Adding Kubernetes apt repository..."
  KUBE_KEYRING="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"
  $SUDO install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key" \
    | $SUDO gpg --dearmor -o "$KUBE_KEYRING"
  echo "deb [signed-by=${KUBE_KEYRING}] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
    | $SUDO tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq kubectl
  log_ok "kubectl installed: $(kubectl version --client --short 2>/dev/null || true)"
fi

# ══════════════════════════════════════════════════════════════
# STEP 5 — Helm
# ══════════════════════════════════════════════════════════════
log_step "Step 5/6 — Helm"

if check_command helm; then
  log_info "Helm version: $(helm version --short)"
else
  log_info "Installing Helm via official script..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  log_ok "Helm installed: $(helm version --short)"
fi

# ══════════════════════════════════════════════════════════════
# STEP 6 — Create kind cluster
# ══════════════════════════════════════════════════════════════
log_step "Step 6/6 — Creating kind cluster: '$KIND_CLUSTER_NAME'"

if kind get clusters 2>/dev/null | grep -q "^${KIND_CLUSTER_NAME}$"; then
  log_warn "Cluster '$KIND_CLUSTER_NAME' already exists — skipping creation"
else
  log_info "Creating cluster with 1 control-plane + 2 worker nodes..."
  cat <<EOF | kind create cluster --name "$KIND_CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 8080
        protocol: TCP
      - containerPort: 443
        hostPort: 8443
        protocol: TCP
  - role: worker
    labels:
      node-type: worker
  - role: worker
    labels:
      node-type: worker
EOF
  log_ok "Cluster '$KIND_CLUSTER_NAME' created"
fi

kubectl config use-context "kind-${KIND_CLUSTER_NAME}" &>/dev/null
log_ok "kubectl context set to: kind-${KIND_CLUSTER_NAME}"

# ══════════════════════════════════════════════════════════════
# FINAL VERIFICATION
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Verification${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${DIM}Cluster nodes:${NC}"
kubectl get nodes -o wide
echo ""
echo -e "${DIM}System pods:${NC}"
kubectl get pods -n kube-system --no-headers | awk '{printf "  %-45s %s\n", $1, $4}'
echo ""
echo -e "${GREEN}${BOLD}  ✅ Linux (Debian) setup complete!${NC}"
echo ""
echo -e "  Run a lab:      ${CYAN}bash q1-lab-setup.sh${NC}"
echo -e "  Validate:       ${CYAN}bash q1-validate.sh${NC}"
echo -e "  Delete cluster: ${CYAN}kind delete cluster --name $KIND_CLUSTER_NAME${NC}"
echo ""

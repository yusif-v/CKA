#!/usr/bin/env bash
# =============================================================
#  CKA Lab — Linux (Fedora/RHEL/CentOS/Rocky/Alma/Arch) Setup
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

# Determine sudo
SUDO=""
if [ "$EUID" -ne 0 ]; then
  if command -v sudo &>/dev/null; then
    SUDO="sudo"
  else
    log_error "Not running as root and 'sudo' not found. Please run as root."
  fi
fi

# Detect distro & package manager
PKG_MANAGER=""
DISTRO_NAME="Unknown"

if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO_NAME="${PRETTY_NAME:-$ID}"
fi

if command -v dnf &>/dev/null; then
  PKG_MANAGER="dnf"
elif command -v yum &>/dev/null; then
  PKG_MANAGER="yum"
elif command -v pacman &>/dev/null; then
  PKG_MANAGER="pacman"
else
  log_error "No supported package manager found (dnf/yum/pacman). Cannot continue."
fi

# ── Banner ───────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  Linux (RPM/Arch) Installer${NC}"
echo -e "  Distro:       ${BOLD}$DISTRO_NAME${NC}"
echo -e "  Package mgr:  ${BOLD}$PKG_MANAGER${NC}"
echo -e "  Architecture: ${BOLD}$ARCH${NC}"
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 1 — Prerequisites
# ══════════════════════════════════════════════════════════════
log_step "Step 1/6 — System update & prerequisites"

case "$PKG_MANAGER" in
  dnf)
    log_info "Updating system..."
    $SUDO dnf update -y -q
    log_info "Installing prerequisites..."
    $SUDO dnf install -y -q \
      curl wget git jq gnupg2 ca-certificates \
      dnf-plugins-core
    ;;
  yum)
    log_info "Updating system..."
    $SUDO yum update -y -q
    log_info "Installing prerequisites..."
    $SUDO yum install -y -q \
      curl wget git jq gnupg2 ca-certificates \
      yum-utils
    ;;
  pacman)
    log_info "Updating system..."
    $SUDO pacman -Syu --noconfirm --quiet
    log_info "Installing prerequisites..."
    $SUDO pacman -S --noconfirm --needed \
      curl wget git jq gnupg ca-certificates
    ;;
esac

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
  case "$PKG_MANAGER" in
    dnf)
      log_info "Adding Docker CE repository..."
      $SUDO dnf config-manager --add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null \
        || $SUDO dnf config-manager --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo

      log_info "Installing Docker CE..."
      $SUDO dnf install -y -q \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
      ;;
    yum)
      log_info "Adding Docker CE repository..."
      $SUDO yum-config-manager --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
      log_info "Installing Docker CE..."
      $SUDO yum install -y -q \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
      ;;
    pacman)
      log_info "Installing Docker via pacman..."
      $SUDO pacman -S --noconfirm --needed docker docker-compose
      ;;
  esac

  log_info "Enabling and starting Docker..."
  $SUDO systemctl enable docker --quiet
  $SUDO systemctl start docker

  # Add user to docker group
  CURRENT_USER="${SUDO_USER:-$USER}"
  if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    $SUDO usermod -aG docker "$CURRENT_USER"
    log_warn "User '$CURRENT_USER' added to 'docker' group."
    log_warn "You may need to log out/in. Using 'newgrp docker' for this session."
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
  if [ "$PKG_MANAGER" = "pacman" ] && command -v paru &>/dev/null; then
    log_info "Installing kind via paru (AUR)..."
    paru -S --noconfirm kind
  else
    log_info "Downloading kind binary for linux/$ARCH..."
    KIND_URL="https://kind.sigs.k8s.io/dl/latest/kind-linux-${ARCH}"
    curl -fsSL "$KIND_URL" -o /tmp/kind
    $SUDO install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
    rm -f /tmp/kind
  fi
  log_ok "kind installed: $(kind version)"
fi

# ══════════════════════════════════════════════════════════════
# STEP 4 — kubectl
# ══════════════════════════════════════════════════════════════
log_step "Step 4/6 — kubectl"

if check_command kubectl; then
  log_info "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  case "$PKG_MANAGER" in
    dnf|yum)
      log_info "Adding Kubernetes repository..."
      cat <<EOF | $SUDO tee /etc/yum.repos.d/kubernetes.repo > /dev/null
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF
      $SUDO $PKG_MANAGER install -y -q kubectl
      ;;
    pacman)
      log_info "Installing kubectl via pacman..."
      $SUDO pacman -S --noconfirm --needed kubectl \
        || (log_info "Not in official repo — downloading binary..." && \
            curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" \
              -o /tmp/kubectl && \
            $SUDO install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl && \
            rm -f /tmp/kubectl)
      ;;
  esac
  log_ok "kubectl installed: $(kubectl version --client --short 2>/dev/null || true)"
fi

# ══════════════════════════════════════════════════════════════
# STEP 5 — Helm
# ══════════════════════════════════════════════════════════════
log_step "Step 5/6 — Helm"

if check_command helm; then
  log_info "Helm version: $(helm version --short)"
else
  case "$PKG_MANAGER" in
    pacman)
      log_info "Installing Helm via pacman..."
      $SUDO pacman -S --noconfirm --needed helm \
        || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      ;;
    *)
      log_info "Installing Helm via official script..."
      curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      ;;
  esac
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
echo -e "${GREEN}${BOLD}  ✅ Linux (RPM/Arch) setup complete!${NC}"
echo ""
echo -e "  Run a lab:      ${CYAN}bash q1-lab-setup.sh${NC}"
echo -e "  Validate:       ${CYAN}bash q1-validate.sh${NC}"
echo -e "  Delete cluster: ${CYAN}kind delete cluster --name $KIND_CLUSTER_NAME${NC}"
echo ""

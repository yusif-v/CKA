#!/usr/bin/env bash
# =============================================================
#  CKA Lab — macOS Setup Script
#  Installs: Homebrew · Docker Desktop · kind · kubectl · helm
# =============================================================

set -euo pipefail

ARCH="${CKA_ARCH:-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')}"
KIND_CLUSTER_NAME="cka-lab"
KIND_VERSION="v0.22.0"
KUBECTL_VERSION="v1.29.2"

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
log_error() { echo -e "  ${RED}✘${NC} $1"; }
log_info()  { echo -e "  ${DIM}→ $1${NC}"; }

check_command() {
  if command -v "$1" &>/dev/null; then
    log_ok "$1 already installed: $(command -v "$1")"
    return 0
  fi
  return 1
}

require_sudo() {
  if [ "$EUID" -eq 0 ]; then
    log_warn "Running as root — some Homebrew operations may behave differently"
  fi
}

# ── Banner ───────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  macOS Installer${NC} ${DIM}(Homebrew-based)${NC}"
echo -e "  Architecture: ${BOLD}$ARCH${NC}"
echo ""

require_sudo

# ══════════════════════════════════════════════════════════════
# STEP 1 — Homebrew
# ══════════════════════════════════════════════════════════════
log_step "Step 1/6 — Homebrew"

if check_command brew; then
  log_info "Updating Homebrew..."
  brew update --quiet
else
  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for Apple Silicon
  if [ "$ARCH" = "arm64" ]; then
    if ! grep -q '/opt/homebrew/bin/brew' ~/.zprofile 2>/dev/null; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
  log_ok "Homebrew installed"
fi

# ══════════════════════════════════════════════════════════════
# STEP 2 — Docker Desktop
# ══════════════════════════════════════════════════════════════
log_step "Step 2/6 — Docker"

if check_command docker; then
  log_info "Checking Docker daemon..."
  if ! docker info &>/dev/null; then
    log_warn "Docker is installed but not running. Attempting to start Docker Desktop..."
    open -a Docker || true
    echo -ne "  ${DIM}Waiting for Docker to start"
    for i in {1..30}; do
      if docker info &>/dev/null; then break; fi
      echo -n "."
      sleep 2
    done
    echo -e "${NC}"
    if ! docker info &>/dev/null; then
      log_error "Docker did not start in time. Please start Docker Desktop manually and re-run."
      exit 1
    fi
  fi
  log_ok "Docker is running"
else
  log_info "Installing Docker Desktop via Homebrew..."
  brew install --cask docker
  log_info "Starting Docker Desktop..."
  open -a Docker || true
  echo -ne "  ${DIM}Waiting for Docker daemon to start"
  for i in {1..40}; do
    if docker info &>/dev/null; then break; fi
    echo -n "."
    sleep 3
  done
  echo -e "${NC}"
  if ! docker info &>/dev/null; then
    log_error "Docker did not start. Please open Docker Desktop manually and re-run."
    exit 1
  fi
  log_ok "Docker Desktop installed and running"
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
  log_info "Installing kind via Homebrew..."
  brew install kind
  log_ok "kind installed: $(kind version)"
fi

# ══════════════════════════════════════════════════════════════
# STEP 4 — kubectl
# ══════════════════════════════════════════════════════════════
log_step "Step 4/6 — kubectl"

if check_command kubectl; then
  log_info "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  log_info "Installing kubectl via Homebrew..."
  brew install kubectl
  log_ok "kubectl installed"
fi

# ══════════════════════════════════════════════════════════════
# STEP 5 — Helm
# ══════════════════════════════════════════════════════════════
log_step "Step 5/6 — Helm"

if check_command helm; then
  log_info "Helm version: $(helm version --short)"
else
  log_info "Installing Helm via Homebrew..."
  brew install helm
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

# Set kubectl context
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
echo -e "${GREEN}${BOLD}  ✅ macOS setup complete!${NC}"
echo ""
echo -e "  Run a lab:      ${CYAN}bash q1-lab-setup.sh${NC}"
echo -e "  Validate:       ${CYAN}bash q1-validate.sh${NC}"
echo -e "  Delete cluster: ${CYAN}kind delete cluster --name $KIND_CLUSTER_NAME${NC}"
echo ""

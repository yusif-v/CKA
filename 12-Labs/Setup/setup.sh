#!/usr/bin/env bash
# =============================================================
#  CKA Lab Environment — Master Setup
#  Detects OS and delegates to the correct platform installer
# =============================================================

set -euo pipefail

# ── Colors & formatting ──────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Banner ───────────────────────────────────────────────────
clear
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔═════════════════════════════════════════════╗"
echo "  ║          CKA Lab Environment Setup          ║"
echo "  ║     Kubernetes-in-Docker (kind) Edition     ║"
echo "  ╚═════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${DIM}  This script installs: Docker · kind · kubectl · helm${NC}"
echo ""

# ── Detect OS ────────────────────────────────────────────────
detect_os() {
  local os=""
  local arch=""

  # Architecture
  case "$(uname -m)" in
    x86_64)  arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      echo -e "${RED}✘ Unsupported architecture: $(uname -m)${NC}"
      exit 1
      ;;
  esac

  # OS
  case "$(uname -s)" in
    Darwin)
      os="macos"
      ;;
    Linux)
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
          ubuntu|debian|linuxmint|pop) os="linux-debian" ;;
          fedora|rhel|centos|rocky|almalinux) os="linux-rpm" ;;
          arch|manjaro) os="linux-arch" ;;
          *)
            echo -e "${YELLOW}⚠ Unknown Linux distro: $ID — attempting Debian-based install${NC}"
            os="linux-debian"
            ;;
        esac
      else
        echo -e "${YELLOW}⚠ Cannot detect Linux distro — attempting Debian-based install${NC}"
        os="linux-debian"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*|Windows_NT)
      os="windows"
      ;;
    *)
      echo -e "${RED}✘ Unsupported OS: $(uname -s)${NC}"
      exit 1
      ;;
  esac

  echo "$os $arch"
}

# ── Main ─────────────────────────────────────────────────────
echo -e "${BOLD}[1/3] Detecting operating system...${NC}"
read -r OS ARCH <<< "$(detect_os)"

echo -e "  ${GREEN}✔${NC} OS      : ${BOLD}$OS${NC}"
echo -e "  ${GREEN}✔${NC} Arch    : ${BOLD}$ARCH${NC}"
echo ""

# ── Delegate to platform script ──────────────────────────────
echo -e "${BOLD}[2/3] Launching platform-specific installer...${NC}"
echo ""

case "$OS" in
  macos)
    INSTALLER="$SCRIPT_DIR/setup-macos.sh"
    ;;
  linux-debian)
    INSTALLER="$SCRIPT_DIR/setup-linux-debian.sh"
    ;;
  linux-rpm)
    INSTALLER="$SCRIPT_DIR/setup-linux-rpm.sh"
    ;;
  linux-arch)
    # Arch uses the RPM script as a fallback with pacman detection inside
    INSTALLER="$SCRIPT_DIR/setup-linux-rpm.sh"
    ;;
  windows)
    echo -e "${YELLOW}${BOLD}"
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │  Windows Detected                       │"
    echo "  │                                         │"
    echo "  │  Please run setup-windows.ps1 instead   │"
    echo "  │  PowerShell (Admin) →                   │"
    echo "  │    .\\setup-windows.ps1                 │"
    echo "  └─────────────────────────────────────────┘"
    echo -e "${NC}"
    exit 0
    ;;
esac

# Check installer script exists
if [ ! -f "$INSTALLER" ]; then
  echo -e "${RED}✘ Installer script not found: $INSTALLER${NC}"
  echo -e "  Make sure all setup scripts are in the same directory."
  exit 1
fi

chmod +x "$INSTALLER"
export CKA_ARCH="$ARCH"
exec "$INSTALLER"

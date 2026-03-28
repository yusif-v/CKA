# =============================================================
#  CKA Lab — Windows Setup Script (PowerShell)
#  Installs: Docker Desktop · kind · kubectl · helm
#  Run in PowerShell as Administrator
# =============================================================
# Usage:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#   .\setup-windows.ps1
# =============================================================

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Colors & helpers ─────────────────────────────────────────
function Write-Step   { param($msg) Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Write-Ok     { param($msg) Write-Host "  ✔ $msg" -ForegroundColor Green }
function Write-Warn   { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Info   { param($msg) Write-Host "  → $msg" -ForegroundColor DarkGray }
function Write-Fail   { param($msg) Write-Host "  ✘ $msg" -ForegroundColor Red; exit 1 }

function Test-Command {
  param($cmd)
  return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Add-ToPath {
  param($dir)
  $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
  if ($currentPath -notlike "*$dir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$dir", "Machine")
    $env:PATH = "$env:PATH;$dir"
    Write-Info "Added '$dir' to system PATH"
  }
}

# ── Admin check ──────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
  Write-Warn "Not running as Administrator — some steps may fail."
  Write-Warn "Re-run PowerShell as Administrator for best results."
  Read-Host "Press Enter to continue anyway, or Ctrl+C to cancel"
}

# Detect architecture
$ARCH = if ([System.Environment]::Is64BitOperatingSystem) {
  if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
} else { "386" }

$KIND_CLUSTER_NAME = "cka-lab"

# ── Banner ───────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║         CKA Lab Environment Setup             ║" -ForegroundColor Cyan
Write-Host "  ║         Windows (PowerShell) Edition          ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Architecture: $ARCH" -ForegroundColor DarkGray
Write-Host ""

# ══════════════════════════════════════════════════════════════
# STEP 1 — Package Manager (winget preferred, choco fallback)
# ══════════════════════════════════════════════════════════════
Write-Step "Step 1/6 — Package Manager"

$USE_WINGET = $false
$USE_CHOCO  = $false

if (Test-Command winget) {
  Write-Ok "winget is available"
  $USE_WINGET = $true
} elseif (Test-Command choco) {
  Write-Ok "Chocolatey is available"
  $USE_CHOCO = $true
} else {
  Write-Info "Neither winget nor Chocolatey found. Installing Chocolatey..."
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  if (Test-Command choco) {
    Write-Ok "Chocolatey installed"
    $USE_CHOCO = $true
  } else {
    Write-Fail "Could not install a package manager. Please install winget or Chocolatey manually."
  }
}

# ══════════════════════════════════════════════════════════════
# STEP 2 — Docker Desktop
# ══════════════════════════════════════════════════════════════
Write-Step "Step 2/6 — Docker Desktop"

if (Test-Command docker) {
  Write-Ok "docker already installed"
  try {
    docker info | Out-Null
    Write-Ok "Docker daemon is running"
  } catch {
    Write-Warn "Docker not running. Please start Docker Desktop manually."
    Write-Info "Waiting 30 seconds for Docker to start..."
    Start-Sleep -Seconds 30
    docker info | Out-Null
  }
} else {
  if ($USE_WINGET) {
    Write-Info "Installing Docker Desktop via winget..."
    winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
  } elseif ($USE_CHOCO) {
    Write-Info "Installing Docker Desktop via Chocolatey..."
    choco install docker-desktop -y
  }

  Write-Warn "Docker Desktop installed. Please START Docker Desktop now."
  Write-Info "After Docker Desktop is running, press Enter to continue..."
  Read-Host

  # Verify
  $attempts = 0
  while ($attempts -lt 15) {
    try {
      docker info | Out-Null
      Write-Ok "Docker daemon is running"
      break
    } catch {
      Write-Info "Waiting for Docker... ($attempts/15)"
      Start-Sleep -Seconds 5
      $attempts++
    }
  }

  if ($attempts -ge 15) {
    Write-Fail "Docker did not start in time. Ensure Docker Desktop is running and retry."
  }
}

$dockerVersion = (docker --version) -replace "Docker version ", ""
Write-Info "Docker version: $dockerVersion"

# ══════════════════════════════════════════════════════════════
# STEP 3 — kind
# ══════════════════════════════════════════════════════════════
Write-Step "Step 3/6 — kind (Kubernetes in Docker)"

if (Test-Command kind) {
  Write-Ok "kind already installed: $(kind version)"
} else {
  if ($USE_WINGET) {
    Write-Info "Installing kind via winget..."
    winget install -e --id Kubernetes.kind --accept-source-agreements
  } elseif ($USE_CHOCO) {
    Write-Info "Installing kind via Chocolatey..."
    choco install kind -y
  } else {
    Write-Info "Downloading kind binary directly..."
    $kindUrl = "https://kind.sigs.k8s.io/dl/latest/kind-windows-${ARCH}.exe"
    $kindPath = "$env:LOCALAPPDATA\Programs\kind\kind.exe"
    New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Programs\kind" | Out-Null
    Invoke-WebRequest -Uri $kindUrl -OutFile $kindPath
    Add-ToPath "$env:LOCALAPPDATA\Programs\kind"
  }
  Write-Ok "kind installed: $(kind version)"
}

# ══════════════════════════════════════════════════════════════
# STEP 4 — kubectl
# ══════════════════════════════════════════════════════════════
Write-Step "Step 4/6 — kubectl"

if (Test-Command kubectl) {
  Write-Ok "kubectl already installed"
  kubectl version --client
} else {
  if ($USE_WINGET) {
    Write-Info "Installing kubectl via winget..."
    winget install -e --id Kubernetes.kubectl --accept-source-agreements
  } elseif ($USE_CHOCO) {
    Write-Info "Installing kubectl via Chocolatey..."
    choco install kubernetes-cli -y
  } else {
    Write-Info "Downloading kubectl binary..."
    $stableVersion = (Invoke-WebRequest "https://dl.k8s.io/release/stable.txt").Content.Trim()
    $kubectlUrl = "https://dl.k8s.io/release/$stableVersion/bin/windows/${ARCH}/kubectl.exe"
    $kubectlPath = "$env:LOCALAPPDATA\Programs\kubectl\kubectl.exe"
    New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Programs\kubectl" | Out-Null
    Invoke-WebRequest -Uri $kubectlUrl -OutFile $kubectlPath
    Add-ToPath "$env:LOCALAPPDATA\Programs\kubectl"
  }
  Write-Ok "kubectl installed"
}

# ══════════════════════════════════════════════════════════════
# STEP 5 — Helm
# ══════════════════════════════════════════════════════════════
Write-Step "Step 5/6 — Helm"

if (Test-Command helm) {
  Write-Ok "Helm already installed: $(helm version --short)"
} else {
  if ($USE_WINGET) {
    Write-Info "Installing Helm via winget..."
    winget install -e --id Helm.Helm --accept-source-agreements
  } elseif ($USE_CHOCO) {
    Write-Info "Installing Helm via Chocolatey..."
    choco install kubernetes-helm -y
  } else {
    Write-Info "Downloading Helm installer..."
    $helmInstaller = "$env:TEMP\get_helm.ps1"
    Invoke-WebRequest "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" -OutFile $helmInstaller
    & $helmInstaller
  }
  Write-Ok "Helm installed: $(helm version --short)"
}

# ══════════════════════════════════════════════════════════════
# STEP 6 — Create kind cluster
# ══════════════════════════════════════════════════════════════
Write-Step "Step 6/6 — Creating kind cluster: '$KIND_CLUSTER_NAME'"

$existingClusters = kind get clusters 2>$null
if ($existingClusters -contains $KIND_CLUSTER_NAME) {
  Write-Warn "Cluster '$KIND_CLUSTER_NAME' already exists — skipping creation"
} else {
  Write-Info "Creating cluster with 1 control-plane + 2 worker nodes..."
  $clusterConfig = @"
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
"@
  $clusterConfig | kind create cluster --name $KIND_CLUSTER_NAME --config=-
  Write-Ok "Cluster '$KIND_CLUSTER_NAME' created"
}

kubectl config use-context "kind-$KIND_CLUSTER_NAME" | Out-Null
Write-Ok "kubectl context set to: kind-$KIND_CLUSTER_NAME"

# ══════════════════════════════════════════════════════════════
# FINAL VERIFICATION
# ══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Verification" -ForegroundColor White
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Cluster nodes:" -ForegroundColor DarkGray
kubectl get nodes -o wide
Write-Host ""
Write-Host "  System pods:" -ForegroundColor DarkGray
kubectl get pods -n kube-system
Write-Host ""
Write-Host "  ✅ Windows setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Run a lab:      bash q1-lab-setup.sh (in Git Bash/WSL)" -ForegroundColor Cyan
Write-Host "  Validate:       bash q1-validate.sh" -ForegroundColor Cyan
Write-Host "  Delete cluster: kind delete cluster --name $KIND_CLUSTER_NAME" -ForegroundColor Cyan
Write-Host ""

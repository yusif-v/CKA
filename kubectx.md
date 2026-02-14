#cli 
# kubectx
## Overview

**kubectx** is a small but mighty CLI utility that lets you switch between Kubernetes contexts instantly, without typing long kubectl config use-context ... commands every five seconds.

It was created by **Ahmet Alp Balkan** to make working with multiple clusters far less painful, and it has become a de-facto companion tool for engineers using **Kubernetes** daily.

Think of it as git checkout, but for clusters.

## Why kubectx Exists

Native Kubernetes way:

```bash
kubectl config get-contexts
kubectl config use-context production-eu-west-1
```

Human brain after typing that 40 times:

```bash
...why is Dev suddenly talking to Prod again?
```

kubectx reduces this to:

```bash
kubectx production
```

Fast. Safe. Less typo-driven chaos.

## Installation

### macOS (Homebrew)

```bash
brew install kubectx
```

### Linux (Manual)

```bash
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
```

## Basic Usage
### List Contexts

```bash
kubectx
```

Example output:

```bash
dev
staging
production
```

The current context is highlighted.

### Switch Context

```bash
kubectx dev
```

Instantly changes your kubeconfig context.

No YAML editing. No long commands. No regrets.

### Switch Back to Previous Context

```bash
kubectx -
```

This is extremely useful when jumping between two clusters during debugging.

## Rename a Context (Yes, Finally)

If your context name looks like:

```bash
gke_project-123456_us-central1_cluster-1
```

You can civilize it:

```bash
kubectx gke_project-123456_us-central1_cluster-1=prod
```

Now you just use:

```bash
kubectx prod
```

Your future self will thank you.

## Delete a Context

```bash
kubectx -d staging
```

Removes it from kubeconfig cleanly.

## kubens (Bundled Tool)

kubectx comes with **kubens**, which switches namespaces instead of clusters.

```bash
kubens kube-system
```

This avoids:

```bash
kubectl config set-context --current --namespace=...
```

Same philosophy: remove friction so you stop making mistakes.

## Why This Tool Matters More Than It Looks

Kubernetes environments multiply:
- local cluster
- test cluster
- staging
- multiple production regions
- temporary debug clusters

Humans are bad at remembering where they are.
kubectx makes the current context visible and changeable in one keystroke, which dramatically reduces “oops I deployed to prod” incidents.

This is one of those tools that doesn’t add power — it removes cognitive load. And removing cognitive load is how complex systems stay survivable.

## Pro Tip

Add this to your shell prompt to always see the active context:

```bash
PS1='[$(kubectl config current-context)] '$PS1
```

Now you get a constant reminder of where your commands are about to land, like a spacecraft HUD for cluster navigation.

kubectx is a classic example of engineering evolution: Kubernetes gave us a powerful machine, and then the community built ergonomic exoskeletons so humans could actually operate it without spraining their brains.
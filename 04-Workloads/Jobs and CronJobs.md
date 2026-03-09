---
tags: [cka/workloads, workloads]
aliases: [Job, CronJob, Batch Job, Batch Workload, batch/v1]
---

# Jobs and CronJobs

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Pods]], [[kube-controller-manager]], [[Deployments]], [[ConfigMap]], [[Secrets]], [[RBAC]]

## Overview

A **Job** creates one or more [[Pods]] to perform a **finite task** and tracks successful completion. Once the required completions are reached, the Job is done — unlike [[Deployments]], which run forever. A **CronJob** wraps a Job in a schedule, creating Jobs automatically at specified times using standard cron syntax. Both belong to the `batch/v1` API group.

---

## Jobs

### Basic Job Definition

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-calculator
spec:
  completions: 1          # How many Pods must succeed (default: 1)
  parallelism: 1          # How many Pods run simultaneously (default: 1)
  backoffLimit: 4         # Retry attempts before Job is marked Failed (default: 6)
  activeDeadlineSeconds: 120   # Kill Job if not done within this many seconds
  template:
    spec:
      restartPolicy: OnFailure  # Must be OnFailure or Never (not Always)
      containers:
      - name: pi
        image: perl:5.34
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
```

> [!warning]
> `restartPolicy: Always` is **not allowed** in Job Pods. You must use `OnFailure` or `Never`.

### restartPolicy — OnFailure vs Never

| Policy | Behaviour on failure |
|---|---|
| `OnFailure` | Restart the container in the same Pod |
| `Never` | Create a new Pod on failure (old Pod stays for debugging) |

Use `Never` when you need to inspect failed Pod logs after failure.

---

### Parallel Jobs — Completion Modes

#### Fixed Completions (most common)

```yaml
spec:
  completions: 5    # 5 Pods must succeed total
  parallelism: 2    # Run 2 at a time
```

Kubernetes keeps spawning Pods until `completions` successes are reached.

#### Work Queue (parallelism only)

```yaml
spec:
  parallelism: 3    # Run 3 Pods simultaneously; each grabs work from a queue
                    # Job completes when any Pod exits 0 AND all others finish
```

Used with an external queue (Redis, RabbitMQ). Omit `completions` for this pattern.

#### Indexed Jobs

```yaml
spec:
  completions: 5
  parallelism: 5
  completionMode: Indexed   # Each Pod gets a unique index (JOB_COMPLETION_INDEX env var)
```

Each Pod knows its index via `$JOB_COMPLETION_INDEX` — useful for sharded work.

---

### Job Lifecycle

```
Job created
  → Pods scheduled and run
  → Pod succeeds (exit 0) → completion count increases
  → All completions reached → Job status: Complete
  → OR failures exceed backoffLimit → Job status: Failed
```

Completed Jobs and their Pods are **not deleted automatically** unless `ttlSecondsAfterFinished` is set:

```yaml
spec:
  ttlSecondsAfterFinished: 300   # Delete Job + Pods 5 minutes after completion
```

---

## CronJobs

### Basic CronJob Definition

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-report
spec:
  schedule: "0 2 * * *"             # Every night at 02:00 UTC
  timeZone: "Europe/London"         # Optional: explicit timezone (k8s 1.27+)
  concurrencyPolicy: Forbid         # What to do if previous Job is still running
  successfulJobsHistoryLimit: 3     # Keep last 3 successful Jobs (default: 3)
  failedJobsHistoryLimit: 1         # Keep last 1 failed Job (default: 1)
  startingDeadlineSeconds: 60       # Skip if Job can't start within 60s of schedule
  suspend: false                    # Set true to pause the CronJob
  jobTemplate:
    spec:
      backoffLimit: 2
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: reporter
            image: my-reporter:1.0
            command: ["/bin/sh", "-c", "python report.py"]
```

### Cron Schedule Syntax

```
┌─────────── minute (0–59)
│ ┌───────── hour (0–23)
│ │ ┌─────── day of month (1–31)
│ │ │ ┌───── month (1–12)
│ │ │ │ ┌─── day of week (0–6, Sunday=0)
│ │ │ │ │
* * * * *
```

| Schedule | Meaning |
|---|---|
| `0 * * * *` | Every hour at :00 |
| `*/15 * * * *` | Every 15 minutes |
| `0 2 * * *` | Every day at 02:00 |
| `0 9 * * 1` | Every Monday at 09:00 |
| `0 0 1 * *` | First day of every month at midnight |
| `@hourly` | Shorthand for `0 * * * *` |
| `@daily` | Shorthand for `0 0 * * *` |

> [!tip] Exam Tip
> Use [crontab.guru](https://crontab.guru) mentally — the exam allows `kubernetes.io/docs`. Cron syntax errors are a common trap.

---

### concurrencyPolicy

Controls what happens when a Job is still running when the next schedule fires:

| Policy | Behaviour |
|---|---|
| `Allow` (default) | Run new Job alongside existing one |
| `Forbid` | Skip new Job if previous is still running |
| `Replace` | Cancel previous Job and start a new one |

---

### CronJob → Job → Pod Hierarchy

```
CronJob
  └── Job (created per schedule tick)
        └── Pod(s) (created by Job controller)
```

Each CronJob execution creates a **new Job** object. You can inspect past Job runs via `kubectl get jobs`.

---

## Key Commands

```bash
# --- Jobs ---

# Create a Job imperatively
kubectl create job my-job --image=busybox -- /bin/sh -c "echo hello"

# Create a Job from a dry run
kubectl create job my-job --image=busybox --dry-run=client -o yaml -- echo hello > job.yaml

# List Jobs
kubectl get jobs

# Describe a Job (see completions, conditions)
kubectl describe job my-job

# Watch Job Pods
kubectl get pods -l job-name=my-job

# Get logs from a Job Pod
kubectl logs -l job-name=my-job

# Delete a Job (and its Pods)
kubectl delete job my-job

# --- CronJobs ---

# Create a CronJob imperatively
kubectl create cronjob my-cron --image=busybox --schedule="*/5 * * * *" -- echo hello

# List CronJobs
kubectl get cronjobs
kubectl get cj           # Short alias

# Describe a CronJob (see last schedule, active jobs)
kubectl describe cronjob my-cron

# Suspend a CronJob (pause scheduling)
kubectl patch cronjob my-cron -p '{"spec":{"suspend":true}}'

# Resume a CronJob
kubectl patch cronjob my-cron -p '{"spec":{"suspend":false}}'

# Manually trigger a CronJob immediately
kubectl create job --from=cronjob/my-cron manual-trigger-01

# View Jobs created by a CronJob
kubectl get jobs -l app=my-cron

# Delete a CronJob (and all its Jobs and Pods)
kubectl delete cronjob my-cron
```

> [!tip] Exam Tip
> `kubectl create job --from=cronjob/<name> <job-name>` is the fastest way to manually trigger a CronJob run — very useful in the exam when asked to "run the job now".

---

## Common Issues / Troubleshooting

- **Job stuck, Pods not completing** → check `backoffLimit`; if exceeded, Job is Failed; inspect Pod logs with `kubectl logs -l job-name=<job>`
- **Pods keep restarting** → `restartPolicy: Always` set; must be `OnFailure` or `Never` for Job Pods
- **CronJob not firing** → check `suspend: true`; check `startingDeadlineSeconds` — if CronJob was missed and deadline passed, it won't catch up
- **Too many Pods accumulating** → `ttlSecondsAfterFinished` not set; or `successfulJobsHistoryLimit` / `failedJobsHistoryLimit` too high
- **Concurrent Jobs piling up** → `concurrencyPolicy: Allow` (default); switch to `Forbid` or `Replace`
- **CronJob ran but created no Job** → missed schedule window; check `startingDeadlineSeconds`
- **Job never starts** → resource limits or [[Taints]] preventing Pod scheduling; check `kubectl describe job` events

---

## Related Notes

- [[Pods]] — Jobs create and manage Pods directly
- [[kube-controller-manager]] — Job Controller and CronJob Controller live here
- [[Deployments]] — For long-running services; contrast with Jobs for finite tasks
- [[ConfigMap]] / [[Secrets]] — Inject config/credentials into Job Pods like any other Pod
- [[RBAC]] — ServiceAccount permissions needed if Job Pods interact with the API
- [[Resource Limits]] — Set on Job Pod containers to prevent runaway batch workloads

---

## Key Mental Model

A **Deployment** is a permanent employee — always on, always running. A **Job** is a contractor hired for one task — works until done, then leaves. A **CronJob** is the staffing agency that keeps hiring that contractor on a schedule. When the task is complete (exit 0), the work is done. The cluster doesn't need to babysit it forever.

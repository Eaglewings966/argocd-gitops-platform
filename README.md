<div align="center">

# 🚀 GitOps Platform — Argo CD App of Apps + Canary Deployments on AWS EKS Fargate

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS_Fargate-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/fargate/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/Argo_CD-2.9-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Helm](https://img.shields.io/badge/Helm-3.0-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh/)
[![Docker](https://img.shields.io/badge/Docker-eaglewings6-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/u/eaglewings6)
[![eksctl](https://img.shields.io/badge/eksctl-Fargate-orange?style=for-the-badge&logo=amazon-eks&logoColor=white)](https://eksctl.io/)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/Eaglewings966/argocd-gitops-platform?style=for-the-badge&color=blue)](https://github.com/Eaglewings966/argocd-gitops-platform)

**A production-grade GitOps platform built on AWS EKS Fargate using Argo CD and Argo Rollouts.**
**Implements the App of Apps pattern and canary progressive delivery with automated rollback.**
**Fully serverless Kubernetes — zero EC2 instances, zero node management.**

[📖 Full Article](https://emmanuelubani.hashnode.dev) •
[💼 LinkedIn](https://linkedin.com/in/ubaniemmanuel) •
[🐙 GitHub](https://github.com/Eaglewings966) •
[🐳 Docker Hub](https://hub.docker.com/u/eaglewings6)

</div>

---

## 📋 Table of Contents

- [The Problem This Solves](#the-problem-this-solves)
- [Why EKS Fargate](#why-eks-fargate)
- [Architecture](#architecture)
- [What This Project Demonstrates](#what-this-project-demonstrates)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Deployment](#deployment)
- [GitOps Flow](#gitops-flow)
- [Outputs](#outputs)
- [Key Lessons Learned](#key-lessons-learned)
- [Author](#author)

---

## 🔥 The Problem This Solves

A startup pushes a bad release to production at 11pm on a Friday.
The new version has a memory leak that staging never caught.
Within 20 minutes pods start crashing. Response times jump from
120 milliseconds to 45 seconds. Users start tweeting.

The on-call engineer wakes up, panics, and starts manually deleting
pods trying to force a rollback. It makes things worse. By 3am
the incident is over. Four hours and nineteen minutes of downtime.
Estimated revenue loss — $140,000.

Every single part of that failure was preventable.

This platform prevents it permanently by:

- Making Git the single source of truth for everything in the cluster
- Automatically detecting and correcting any drift from desired state
- Shifting traffic gradually from 20% to 100% on every deployment
- Rolling back instantly and automatically if health checks fail
- Running entirely on AWS Fargate — no EC2 nodes to manage or patch

---

## ☁️ Why EKS Fargate

This project uses AWS Fargate instead of EC2 node groups for a
deliberate architectural reason — not just as a workaround.

Fargate is a serverless compute engine for Kubernetes. AWS manages
the underlying infrastructure completely. You define what your pods
need in terms of CPU and memory. AWS handles the rest.

Benefits over EC2 node groups:

- Zero node management — no patching, no AMI updates, no node draining
- Pay only for what your pods actually use — no idle node costs
- No vCPU quota issues on new AWS accounts
- No EC2 Fleet Request quotas to worry about
- Production-grade architecture used by Airbnb, Expedia, and Samsung

The tradeoff is that Fargate pods run in private subnets only.
For external access this project uses kubectl port-forward locally
which is the correct approach for a portfolio and development environment.

---

## 🏗️ Architecture
```
                    ┌─────────────────────────────────────────┐
                    │           DEVELOPER WORKFLOW             │
                    │                                          │
                    │   git push → GitHub Repository          │
                    │   github.com/Eaglewings966/              │
                    │   argocd-gitops-platform                 │
                    └────────────────┬─────────────────────────┘
                                     │
                                     │  Argo CD polls every 3 min
                                     ▼
┌────────────────────────────────────────────────────────────────────┐
│                        AWS us-east-1                               │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                  VPC (created by eksctl)                     │  │
│  │                                                              │  │
│  │  ┌─────────────────────┐  ┌─────────────────────────────┐   │  │
│  │  │  Public Subnets     │  │  Private Subnets            │   │  │
│  │  │  (NAT Gateway)      │  │  (Fargate pods run here)    │   │  │
│  │  └─────────────────────┘  └──────────────┬──────────────┘   │  │
│  │                                           │                  │  │
│  │              ┌────────────────────────────▼───────────────┐  │  │
│  │              │      EKS Cluster: emmanuel-gitops          │  │  │
│  │              │      Kubernetes v1.29 — Fargate Only       │  │  │
│  │              │                                            │  │  │
│  │              │  ┌──────────────────────────────────────┐  │  │  │
│  │              │  │  argocd namespace                    │  │  │  │
│  │              │  │  Fargate Profile: fp-argocd          │  │  │  │
│  │              │  │  ┌────────────────────────────────┐  │  │  │  │
│  │              │  │  │  Argo CD Server                │  │  │  │  │
│  │              │  │  │  root-app ──► watches Git      │  │  │  │  │
│  │              │  │  │  demo-app ──► synced from Git  │  │  │  │  │
│  │              │  │  └────────────────────────────────┘  │  │  │  │
│  │              │  └──────────────────────────────────────┘  │  │  │
│  │              │                                            │  │  │
│  │              │  ┌──────────────────────────────────────┐  │  │  │
│  │              │  │  argo-rollouts namespace             │  │  │  │
│  │              │  │  Fargate Profile: fp-argo-rollouts   │  │  │  │
│  │              │  │  ┌────────────────────────────────┐  │  │  │  │
│  │              │  │  │  Argo Rollouts Controller      │  │  │  │  │
│  │              │  │  │  Canary: 20%→40%→60%→80%→100% │  │  │  │  │
│  │              │  │  │  Auto rollback on failure      │  │  │  │  │
│  │              │  │  └────────────────────────────────┘  │  │  │  │
│  │              │  └──────────────────────────────────────┘  │  │  │
│  │              │                                            │  │  │
│  │              │  ┌──────────────────────────────────────┐  │  │  │
│  │              │  │  devops-demo namespace               │  │  │  │
│  │              │  │  Fargate Profile: fp-devops-demo     │  │  │  │
│  │              │  │  ┌──────────────┐ ┌──────────────┐   │  │  │  │
│  │              │  │  │  Stable Pod  │ │  Canary Pod  │   │  │  │  │
│  │              │  │  │  (80% traffic│ │  (20% traffic│   │  │  │  │
│  │              │  │  │   active svc)│ │  preview svc)│   │  │  │  │
│  │              │  │  └──────────────┘ └──────────────┘   │  │  │  │
│  │              │  │                                      │  │  │  │
│  │              │  │  image: eaglewings6/devops-demo-app  │  │  │  │
│  │              │  └──────────────────────────────────────┘  │  │  │
│  │              │                                            │  │  │
│  │              │  kubectl port-forward → localhost:8080     │  │  │
│  │              └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
                              ▲
                              │
                    👨‍💻 Engineer accesses
                    Argo CD UI via
                    kubectl port-forward
                    localhost:8080
```

---

## 🎯 What This Project Demonstrates

- Creating a serverless EKS cluster on AWS Fargate using eksctl
- Understanding why Fargate bypasses EC2 vCPU and Fleet Request quotas
- Provisioning Kubernetes namespaces and installing Argo CD via Terraform and Helm
- Implementing the App of Apps pattern to manage multiple applications from one Git repo
- Creating dedicated Fargate profiles for every namespace that runs pods
- Configuring Argo Rollouts for canary progressive delivery with automated traffic shifting
- Using active and preview services to separate stable and canary traffic cleanly
- Enabling GitOps self-healing so any manual cluster change is automatically reverted
- Destroying everything cleanly with one eksctl command to avoid unexpected charges

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| eksctl v0.170+ | Creates EKS Fargate cluster and Fargate profiles |
| AWS EKS v1.29 | Managed Kubernetes control plane |
| AWS Fargate | Serverless compute — zero EC2 nodes to manage |
| Terraform v1.5+ | IAM roles, namespaces, and Argo CD Helm installation |
| Argo CD v2.9 | GitOps engine — syncs Git state to the cluster |
| Argo Rollouts v1.6 | Progressive canary delivery with automated rollback |
| Helm v3 | Installs Argo CD and Argo Rollouts into the cluster |
| kubectl | Kubernetes CLI for verification and port-forwarding |
| Docker Hub | Container registry — eaglewings6/devops-demo-app:latest |
| GitHub | Single source of truth for all platform configuration |

---

## 📁 Project Structure
```
argocd-gitops-platform/
│
├── terraform/                       # Infrastructure as code
│   ├── main.tf                      # IAM roles and Argo CD Helm installation
│   ├── variables.tf                 # Input variables for the stack
│   ├── outputs.tf                   # Useful commands and cluster info
│   └── versions.tf                  # Provider version constraints
│
├── argocd/                          # Argo CD configuration
│   ├── root-app/
│   │   └── root-application.yaml   # Parent app managing all child apps
│   └── apps/
│       └── demo-app.yaml           # Child app manifest for demo application
│
├── apps/                            # Application Kubernetes manifests
│   └── demo-app/
│       ├── namespace.yaml           # Creates devops-demo namespace
│       ├── rollout.yaml             # Argo Rollout with canary strategy
│       ├── active-service.yaml      # ClusterIP service for stable traffic
│       └── preview-service.yaml     # ClusterIP service for canary traffic
│
├── .gitignore                       # Excludes tfstate, tfvars, .terraform/
└── README.md                        # This file
```

---

## ✅ Prerequisites

| Requirement | Version | How to Verify |
|-------------|---------|---------------|
| AWS CLI | v2.x | `aws --version` |
| eksctl | v0.170+ | `eksctl version` |
| Terraform | v1.5+ | `terraform --version` |
| kubectl | Latest | `kubectl version --client` |
| Helm | v3.x | `helm version` |
| AWS Account | Any | `aws sts get-caller-identity` |
| Docker Hub | Any | hub.docker.com/u/eaglewings6 |
| GitHub Account | Any | github.com/Eaglewings966 |

⚠️ This project uses AWS Fargate instead of EC2 node groups.
Fargate bypasses all vCPU and EC2 Fleet Request quotas completely.
No quota increase requests are needed to run this project.

---

## 🚀 Deployment

### Phase 1 — Create the EKS Fargate Cluster
```bash
# Create the cluster — this takes 15 to 20 minutes
eksctl create cluster \
  --name emmanuel-gitops \
  --region us-east-1 \
  --fargate
```
```bash
# Verify the cluster is active
kubectl get nodes
# Note: Fargate shows no nodes here — that is expected and correct
```

### Phase 2 — Create Fargate Profiles for Every Namespace
```bash
# Profile for Argo CD
eksctl create fargateprofile \
  --cluster emmanuel-gitops \
  --region us-east-1 \
  --name fp-argocd \
  --namespace argocd

# Profile for Argo Rollouts
eksctl create fargateprofile \
  --cluster emmanuel-gitops \
  --region us-east-1 \
  --name fp-argo-rollouts \
  --namespace argo-rollouts

# Profile for the demo application
eksctl create fargateprofile \
  --cluster emmanuel-gitops \
  --region us-east-1 \
  --name fp-devops-demo \
  --namespace devops-demo
```

### Phase 3 — Deploy Argo CD and Argo Rollouts With Terraform
```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply --auto-approve
```

### Phase 4 — Verify Argo CD Is Running
```bash
kubectl get pods -n argocd
# Wait until all pods show Running status
```

### Phase 5 — Access Argo CD UI
```bash
# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo

# Port-forward to access the UI locally
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open in browser: https://localhost:8080
# Username: admin
# Password: from the command above
```

### Phase 6 — Push to GitHub Then Deploy Root App
```bash
# Push code first — Argo CD reads from GitHub
git add .
git commit -m "feat: GitOps platform with Argo CD app-of-apps and canary rollouts"
git branch -M main
git push -u origin main

# Then deploy the root application
kubectl apply -f argocd/root-app/root-application.yaml
```

### Phase 7 — Watch the GitOps Magic
```bash
# Watch all apps sync
argocd app list

# Watch the canary rollout in real time
kubectl argo rollouts get rollout demo-app \
  -n devops-demo --watch
```

### Phase 8 — Access Argo Rollouts Dashboard
```bash
kubectl argo rollouts dashboard &
# Open http://localhost:3100
```

### Phase 9 — ⚠️ DESTROY EVERYTHING WHEN DONE
```bash
# Step 1 — Delete all Argo CD applications
kubectl delete application --all -n argocd

# Step 2 — Delete application namespaces
kubectl delete namespace devops-demo --ignore-not-found=true
kubectl delete namespace argo-rollouts --ignore-not-found=true
kubectl delete namespace argocd --ignore-not-found=true

# Step 3 — Destroy Terraform resources
cd terraform && terraform destroy --auto-approve

# Step 4 — Delete the EKS Fargate cluster
eksctl delete cluster \
  --name emmanuel-gitops \
  --region us-east-1

# Step 5 — Verify in AWS console that these are all gone:
# EKS cluster, Fargate profiles, VPC, NAT Gateway, IAM roles
```

---

## 🔄 GitOps Flow
```
Developer pushes to GitHub
          ↓
Argo CD detects change (every 3 minutes)
          ↓
Argo CD syncs desired state from Git to cluster
          ↓
Argo Rollouts executes canary strategy
          ↓
20% traffic → health check → 40% → health check
→ 60% → 80% → 100%
          ↓
Health check passes → promotion continues
Health check fails → automatic rollback to stable
```

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| cluster_name | emmanuel-gitops |
| region | us-east-1 |
| argocd_namespace | argocd |
| get_argocd_password | Command to retrieve admin password |
| port_forward_command | Command to access Argo CD UI locally |
| rollout_watch_command | Command to watch canary rollout live |
| destroy_command | Full cluster deletion command |

---

## 💡 Key Lessons Learned

**1. Fargate shows zero nodes and that is completely normal**
When you run `kubectl get nodes` on a Fargate cluster, you see
nothing. This alarmed me the first time. On Fargate, AWS provisions
compute invisibly for each pod. There are no persistent nodes to
list. If you see zero nodes and your pods are running, everything
is working exactly as designed.

**2. Every namespace needs its own Fargate profile before pods can schedule**
This is the single most common mistake when working with EKS Fargate.
If you try to deploy a pod into a namespace that has no matching
Fargate profile, the pod will stay in Pending state forever.
No error message. No warning. Just Pending. Always create the
Fargate profile before deploying into any namespace.

**3. Push to GitHub before applying the root app**
Argo CD reads your manifests directly from your GitHub repository.
If you apply the root application before pushing your code, Argo CD
enters a ComparisonError state and shows a repository not found
message. The fix is always to push first and apply second.

**4. The destroy order matters more than you think**
Deleting Argo CD applications before running eksctl delete cluster
is critical. Kubernetes LoadBalancer and service resources created
inside the cluster can leave orphaned AWS resources if the cluster
is deleted first. These orphaned resources keep charging your
account silently. Always clean up Kubernetes resources first,
then destroy the cluster.

**5. Fargate minimum resource requests are non-negotiable**
Every container on Fargate must request at least 0.25 vCPU and
512Mi memory. If your container requests less than this, the pod
will fail to schedule with a cryptic error message. Always set
your resource requests explicitly and at or above the Fargate minimum.

---

## 👨‍💻 Author

<div align="center">

**Emmanuel Ubani**
Cloud and DevOps Engineer — Lagos, Nigeria

*From zoo volunteer to Cloud and DevOps Engineer.*
*Building in public. One project at a time.*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-ubaniemmanuel-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/ubaniemmanuel)
[![GitHub](https://img.shields.io/badge/GitHub-Eaglewings966-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Eaglewings966)
[![Hashnode](https://img.shields.io/badge/Hashnode-emmanuelubani-2962FF?style=for-the-badge&logo=hashnode&logoColor=white)](https://emmanuelubani.hashnode.dev)
[![Medium](https://img.shields.io/badge/Medium-emmaubani966-000000?style=for-the-badge&logo=medium&logoColor=white)](https://medium.com/@emmaubani966)
[![Docker Hub](https://img.shields.io/badge/Docker_Hub-eaglewings6-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/u/eaglewings6)

</div>
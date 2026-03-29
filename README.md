<div align="center">

# 🚀 Production-Grade GitOps Platform
## AWS EKS Fargate · Argo CD · Argo Rollouts · GitHub Actions · Terraform

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS_Fargate-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/fargate/)
[![Argo CD](https://img.shields.io/badge/Argo_CD-2.9-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Argo Rollouts](https://img.shields.io/badge/Argo_Rollouts-1.6-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/rollouts/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Helm](https://img.shields.io/badge/Helm-3.0-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker_Hub-eaglewings6-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/u/eaglewings6)
[![eksctl](https://img.shields.io/badge/eksctl-0.220.0-FF9900?style=for-the-badge)](https://eksctl.io/)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/Eaglewings966/argocd-gitops-platform?style=for-the-badge&color=3b82f6)](https://github.com/Eaglewings966/argocd-gitops-platform)

<br/>

**A production-grade GitOps platform that makes bad deployments architecturally impossible.**
**Zero EC2 instances. Zero node management. Zero 2am incident calls.**

<br/>

[📖 Full Article](https://emmanuelubani.hashnode.dev) •
[💼 LinkedIn](https://linkedin.com/in/ubaniemmanuel) •
[🐙 GitHub](https://github.com/Eaglewings966) •
[🐳 Docker Hub](https://hub.docker.com/u/eaglewings6) •
[🌐 Portfolio](https://ops-run.lovable.app)

</div>

---

## 📋 Table of Contents

- [The Problem — A Real $140,000 Friday Night](#the-problem)
- [Why This Architecture](#why-this-architecture)
- [Architecture Diagram](#architecture-diagram)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Deployment — Phase by Phase](#deployment)
- [GitOps Flow](#gitops-flow)
- [GitHub Actions CI/CD](#github-actions)
- [Canary Rollout Demo](#canary-rollout-demo)
- [Key Lessons Learned](#key-lessons-learned)
- [Destroy Everything](#destroy-everything)
- [Author](#author)

---

## 🔥 The Problem — A Real $140,000 Friday Night <a name="the-problem"></a>

11:47pm. Friday night.

A startup's lead engineer merges a new feature to main.
The CI pipeline passes. All 847 automated tests go green.
He closes his laptop and goes to bed feeling good.

At 11:53pm the deployment hits production.

The new version has a memory leak.
Not a dramatic one. A slow one.
The kind that staging load tests never catch
because staging never gets real traffic.

By 12:14am, pods start breaching memory limits.
Kubernetes kills them. Restarts them.
They breach the limit again. Die again. Restart again.
The entire application tier is caught in a crash loop.

Response times go from 180 milliseconds to 44 seconds.
Payment transactions start timing out.
Users take to Twitter.

The on-call engineer — six weeks into the job —
wakes up to 47 unread Slack messages.

He panics.
He starts deleting pods manually trying to force a rollback.
In the chaos he deletes a ConfigMap
that three separate services use for database connection strings.

Now three services are completely down instead of one slow one.

The incident lasts four hours and twenty-two minutes.
Post-mortem revenue loss estimate: **$140,000.**
The junior engineer is not fired.
But he carries that night with him for a very long time.

---

**Every part of that disaster was architecturally preventable.**

With this GitOps platform:

The new version would have received **20% of traffic first.**
The memory leak would have triggered health check failures within 60 seconds.
Argo Rollouts would have **automatically rolled back** to the stable version.
**Zero manual intervention. Zero deleted ConfigMaps. Zero $140,000.**

This is what this repository builds.

---

## 🧠 Why This Architecture <a name="why-this-architecture"></a>

Every tool in this stack was chosen to solve a specific production problem:

| Tool | Problem It Solves |
|------|------------------|
| **AWS Fargate** | Eliminates EC2 node management, patching, and scaling overhead entirely |
| **eksctl** | Creates a production-ready EKS cluster with correct networking in one command |
| **Argo CD** | Makes Git the single source of truth — manual cluster changes are automatically reverted |
| **App of Apps** | Scales application management from 3 apps to 300 apps without workflow changes |
| **Argo Rollouts** | Prevents bad deployments from reaching all users simultaneously |
| **Canary Strategy** | Tests new versions on real production traffic before full rollout |
| **GitHub Actions** | Closes the GitOps loop — every push to main automatically triggers a sync |
| **Terraform + Helm** | Makes Argo CD installation itself version-controlled and reproducible |
| **Self-healing** | Any manual cluster change is automatically reverted to match Git within 3 minutes |

---

## 🏗️ Architecture Diagram <a name="architecture-diagram"></a>
```
┌──────────────────────────────────────────────────────────────────────┐
│                        DEVELOPER WORKFLOW                            │
│                                                                      │
│   git push to main                                                   │
│         │                                                            │
│         ▼                                                            │
│   GitHub Actions runs gitops-sync.yml                               │
│         │                                                            │
│         ▼                                                            │
│   argocd app sync root-app ──► triggers all child apps              │
└──────────────────────────────┬───────────────────────────────────────┘
                               │
                               │ Argo CD polls every 3 min
                               │ GitHub Actions triggers on push
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      AWS us-east-1                                   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │              VPC (created by eksctl)                           │  │
│  │                                                                │  │
│  │  ┌─────────────────────┐    ┌─────────────────────────────┐   │  │
│  │  │   Public Subnets    │    │   Private Subnets           │   │  │
│  │  │   NAT Gateway       │    │   Fargate pods run here     │   │  │
│  │  └─────────────────────┘    └──────────────┬──────────────┘   │  │
│  │                                             │                  │  │
│  │         ┌───────────────────────────────────▼───────────────┐  │  │
│  │         │       EKS Cluster: emmanuel-gitops                │  │  │
│  │         │       Kubernetes v1.29 — 100% Fargate             │  │  │
│  │         │       Zero EC2 instances                          │  │  │
│  │         │                                                   │  │  │
│  │         │  ┌─────────────────────────────────────────────┐  │  │  │
│  │         │  │  namespace: argocd                          │  │  │  │
│  │         │  │  Fargate profile: fp-argocd                 │  │  │  │
│  │         │  │                                             │  │  │  │
│  │         │  │  ┌──────────────────────────────────────┐   │  │  │  │
│  │         │  │  │  Argo CD Server                      │   │  │  │  │
│  │         │  │  │                                      │   │  │  │  │
│  │         │  │  │  root-app ──watches──► argocd/apps/  │   │  │  │  │
│  │         │  │  │     │                                │   │  │  │  │
│  │         │  │  │     ├──► devops-demo-app             │   │  │  │  │
│  │         │  │  │     └──► argo-rollouts-config        │   │  │  │  │
│  │         │  │  └──────────────────────────────────────┘   │  │  │  │
│  │         │  └─────────────────────────────────────────────┘  │  │  │
│  │         │                                                   │  │  │
│  │         │  ┌─────────────────────────────────────────────┐  │  │  │
│  │         │  │  namespace: argo-rollouts                   │  │  │  │
│  │         │  │  Fargate profile: fp-argo-rollouts          │  │  │  │
│  │         │  │                                             │  │  │  │
│  │         │  │  ┌──────────────────────────────────────┐   │  │  │  │
│  │         │  │  │  Argo Rollouts Controller            │   │  │  │  │
│  │         │  │  │  Canary: 20% → 50% → 100%            │   │  │  │  │
│  │         │  │  │  Automatic rollback on failure        │   │  │  │  │
│  │         │  │  └──────────────────────────────────────┘   │  │  │  │
│  │         │  └─────────────────────────────────────────────┘  │  │  │
│  │         │                                                   │  │  │
│  │         │  ┌─────────────────────────────────────────────┐  │  │  │
│  │         │  │  namespace: devops-demo                     │  │  │  │
│  │         │  │  Fargate profile: fp-devops-demo            │  │  │  │
│  │         │  │                                             │  │  │  │
│  │         │  │  ┌──────────────┐  ┌────────────────────┐   │  │  │  │
│  │         │  │  │ Stable Pods  │  │   Canary Pod       │   │  │  │  │
│  │         │  │  │ 80% traffic  │  │   20% traffic      │   │  │  │  │
│  │         │  │  │ svc: stable  │  │   svc: canary      │   │  │  │  │
│  │         │  │  └──────────────┘  └────────────────────┘   │  │  │  │
│  │         │  │  image: eaglewings6/devops-demo-app:latest   │  │  │  │
│  │         │  │  port: 3000                                  │  │  │  │
│  │         │  └─────────────────────────────────────────────┘  │  │  │
│  │         │                                                   │  │  │
│  │         │  kubectl port-forward → localhost:8080            │  │  │
│  │         └───────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack <a name="tech-stack"></a>

| Tool | Version | Purpose |
|------|---------|---------|
| eksctl | 0.220.0 | EKS Fargate cluster and Fargate profile provisioning |
| AWS EKS | 1.29 | Managed Kubernetes control plane |
| AWS Fargate | Latest | Serverless container compute — zero EC2 nodes |
| Terraform | 1.5+ | Namespace and Helm release management |
| Helm | 3.x | Package management for Argo CD and Argo Rollouts |
| Argo CD | 2.9 | GitOps continuous delivery engine |
| Argo Rollouts | 1.6 | Progressive canary delivery with automated rollback |
| GitHub Actions | Latest | CI/CD pipeline triggering Argo CD sync on every push |
| kubectl | Latest | Cluster verification and port-forwarding |
| Docker Hub | Latest | Container registry — eaglewings6/devops-demo-app:latest |

---

## 📁 Project Structure <a name="project-structure"></a>
```
argocd-gitops-platform/
│
├── .github/
│   └── workflows/
│       └── gitops-sync.yml        # GitHub Actions — triggers Argo CD sync on push
│
├── terraform/
│   ├── main.tf                    # Namespaces + Argo CD + Argo Rollouts via Helm
│   ├── variables.tf               # All configurable input variables
│   ├── outputs.tf                 # Useful commands output after apply
│   └── versions.tf                # Provider version constraints
│
├── argocd/
│   └── apps/
│       ├── root-app.yaml          # Parent app — watches argocd/apps/ folder in Git
│       ├── devops-demo-app.yaml   # Child app — deploys k8s/ manifests
│       └── argo-rollouts-app.yaml # Child app — manages Argo Rollouts config
│
├── k8s/
│   ├── namespace.yaml             # devops-demo namespace with GitOps labels
│   ├── rollout.yaml               # Argo Rollout with 20/50/100 canary strategy
│   └── service.yaml               # Stable and canary ClusterIP services
│
├── .gitignore                     # Excludes tfstate, tfvars, .terraform/, secrets
└── README.md                      # This file
```

---

## ✅ Prerequisites <a name="prerequisites"></a>

| Tool | Version | Install | Verify |
|------|---------|---------|--------|
| AWS CLI | v2.x | [docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | `aws --version` |
| eksctl | v0.220.0 | [eksctl.io](https://eksctl.io/installation/) | `eksctl version` |
| Terraform | v1.5+ | [terraform.io](https://developer.hashicorp.com/terraform/install) | `terraform --version` |
| kubectl | Latest | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) | `kubectl version --client` |
| Helm | v3.x | [helm.sh](https://helm.sh/docs/intro/install/) | `helm version` |
| Argo CD CLI | Latest | [argo-cd releases](https://github.com/argoproj/argo-cd/releases) | `argocd version --client` |
| AWS Account | Any | [aws.amazon.com](https://aws.amazon.com) | `aws sts get-caller-identity` |

> ⚠️ **This project uses AWS Fargate exclusively.**
> No EC2 instances are required. No vCPU quota increases needed.
> Fargate bypasses all EC2 Fleet Request quotas completely.

---

## 🚀 Deployment — Phase by Phase <a name="deployment"></a>

### Phase 1 — Create the EKS Fargate Cluster
```bash
# This single command creates the entire cluster
# VPC, public and private subnets, NAT Gateway,
# EKS control plane, and default Fargate profile
eksctl create cluster \
  --name emmanuel-gitops \
  --region us-east-1 \
  --fargate

# Verify cluster is active
aws eks describe-cluster \
  --name emmanuel-gitops \
  --region us-east-1 \
  --query cluster.status

# Configure kubectl
aws eks update-kubeconfig \
  --region us-east-1 \
  --name emmanuel-gitops
```

> ⚠️ This takes 15 to 20 minutes. Do not cancel it.
> Running `kubectl get nodes` will show zero nodes. This is correct on Fargate.

---

### Phase 2 — Create Fargate Profiles

> ⚠️ Every namespace that runs pods needs its own Fargate profile.
> Without this, pods stay in Pending state forever with no error message.
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

# Verify all profiles are Active
eksctl get fargateprofile \
  --cluster emmanuel-gitops \
  --region us-east-1
```

---

### Phase 3 — Deploy Argo CD and Argo Rollouts With Terraform
```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply --auto-approve
```

> Terraform creates the namespaces and installs Argo CD and Argo Rollouts
> via Helm with Fargate-compatible resource requests on every component.
```bash
# Verify all Argo CD pods are Running
kubectl get pods -n argocd

# Verify Argo Rollouts pods are Running
kubectl get pods -n argo-rollouts
```

> ⚠️ On Fargate, pods take 3 to 5 minutes longer to start than on EC2.
> AWS provisions compute per pod. Give it time before troubleshooting.

---

### Phase 4 — Access Argo CD and Deploy the Root App
```bash
# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo

# Port-forward to access the UI
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Open in browser: http://localhost:8080
# Username: admin
# Password: from the command above
```
```bash
# Push your code to GitHub first
git add .
git commit -m "feat: production GitOps platform with Argo CD and canary rollouts"
git branch -M main
git push -u origin main

# Then deploy the root application
kubectl apply -f argocd/apps/root-app.yaml

# Watch all child apps appear and sync
argocd login localhost:8080 \
  --username admin \
  --password YOUR_PASSWORD \
  --insecure

argocd app list
```

---

### Phase 5 — Watch the Canary Rollout
```bash
# Install the Argo Rollouts kubectl plugin
curl -LO \
  https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Watch the rollout in real time
kubectl argo rollouts get rollout devops-demo-rollout \
  -n devops-demo --watch

# Open the Argo Rollouts dashboard
kubectl argo rollouts dashboard &
# Open http://localhost:3100
```

---

## 🔄 GitOps Flow <a name="gitops-flow"></a>
```
Developer pushes to main
          │
          ▼
GitHub Actions triggers (gitops-sync.yml)
          │
          ▼
argocd app sync root-app
          │
          ▼
Argo CD detects changes in argocd/apps/ and k8s/
          │
          ▼
Argo CD syncs all child applications
          │
          ▼
Argo Rollouts executes canary strategy
          │
     ┌────┴────┐
     │         │
  20% → wait  80% stable traffic
     │
     ▼
  Health check passes → promote to 50%
     │
     ▼
  Health check passes → promote to 100%
     │
     ▼
  Health check fails at any step
     │
     ▼
  Automatic rollback → 100% stable
  Zero manual intervention
```

---

## ⚙️ GitHub Actions CI/CD <a name="github-actions"></a>

The `.github/workflows/gitops-sync.yml` workflow closes the GitOps loop.

On every push to `main`:

1. GitHub Actions installs the Argo CD CLI
2. Logs into Argo CD using `ARGOCD_SERVER` and `ARGOCD_AUTH_TOKEN` secrets
3. Triggers a hard refresh on `root-app` to force Git re-evaluation
4. Syncs all child applications
5. Waits for health confirmation
6. Prints final sync status of all applications

**Required GitHub Secrets:**

| Secret | Description |
|--------|-------------|
| `ARGOCD_SERVER` | Your Argo CD server address from port-forward or ingress |
| `ARGOCD_AUTH_TOKEN` | Argo CD API token — generate with `argocd account generate-token` |

---

## 🚦 Canary Rollout Demo <a name="canary-rollout-demo"></a>

To trigger a new canary rollout, update the image tag in `k8s/rollout.yaml`
and push to main:
```bash
# Edit rollout.yaml — change image tag from :latest to :v2
# Then push
git add k8s/rollout.yaml
git commit -m "deploy: update devops-demo to v2"
git push

# Watch the canary progress
kubectl argo rollouts get rollout devops-demo-rollout \
  -n devops-demo --watch
```

You will see traffic shift:
- `0% → 20%` — canary pod receives first traffic
- `20% → 50%` — promoted after 60 seconds of healthy checks
- `50% → 100%` — full rollout
- Automatic rollback to 0% if health checks fail at any step

---

## 💡 Key Lessons Learned <a name="key-lessons-learned"></a>

**1. Fargate shows zero nodes and that is completely correct**
`kubectl get nodes` returns nothing on a Fargate cluster.
This is expected behaviour. Fargate provisions compute
invisibly per pod. Zero nodes does not mean something is broken.
It means Fargate is working exactly as designed.

**2. Every namespace needs its own Fargate profile before pods can schedule**
This is the most common Fargate mistake. A pod deployed into
a namespace with no matching Fargate profile stays in Pending
state indefinitely. No error message. No warning. Just waiting forever.
Create the profile before the namespace is used. Every single time.

**3. Push to GitHub before applying the root app**
Argo CD reads directly from your GitHub repository. Applying
the root application before pushing your manifests results in
a ComparisonError — Argo CD cannot find the path it was told
to watch. Always push first. Apply second. Never the other way around.

**4. Fargate resource requests are not optional**
Every container on Fargate must explicitly declare CPU and memory
requests of at least 250m CPU and 512Mi memory. Containers
without explicit requests fail to schedule with an unhelpful
error message. Set requests on every container including Argo CD
internal components like redis, applicationSet, and notifications.

**5. The destroy order prevents orphaned AWS resources**
Deleting Kubernetes resources before running eksctl delete cluster
is critical. If you destroy the cluster first, any AWS resources
created by Kubernetes services — load balancers, security groups —
become orphaned and continue charging your account silently.
Always clean up Kubernetes resources first then destroy the cluster.

**6. Self-healing is a feature not a bug**
The first time Argo CD reverts a change you made manually to the
cluster, it feels like a fight. It is not. Argo CD is doing exactly
what it is supposed to do. If you need to make a change, make it
in Git and push. The cluster will converge to it within 3 minutes.
That discipline is what makes GitOps reliable at scale.

---

## 🗑️ Destroy Everything <a name="destroy-everything"></a>

Run in this exact order to avoid orphaned AWS resources:
```bash
# Step 1 — Delete all Argo CD applications
kubectl delete application --all -n argocd

# Step 2 — Delete application namespaces
kubectl delete namespace devops-demo --ignore-not-found=true
kubectl delete namespace argo-rollouts --ignore-not-found=true
kubectl delete namespace argocd --ignore-not-found=true

# Step 3 — Destroy Terraform resources
cd terraform && terraform destroy --auto-approve

# Step 4 — Delete the entire EKS Fargate cluster
eksctl delete cluster \
  --name emmanuel-gitops \
  --region us-east-1

# Step 5 — Verify in AWS console
# Confirm these are all gone:
# EKS cluster, Fargate profiles, VPC, NAT Gateway, IAM roles
```

---

## 👨‍💻 Author <a name="author"></a>

<div align="center">

**Emmanuel Ubani**
Cloud and DevOps Engineer — Lagos, Nigeria

*From zoo volunteer to Cloud and DevOps Engineer.*
*Building enterprise infrastructure in public.*
*One project at a time.*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-ubaniemmanuel-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/ubaniemmanuel)
[![GitHub](https://img.shields.io/badge/GitHub-Eaglewings966-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Eaglewings966)
[![Hashnode](https://img.shields.io/badge/Hashnode-emmanuelubani-2962FF?style=for-the-badge&logo=hashnode&logoColor=white)](https://emmanuelubani.hashnode.dev)
[![Medium](https://img.shields.io/badge/Medium-emmaubani966-000000?style=for-the-badge&logo=medium&logoColor=white)](https://medium.com/@emmaubani966)
[![Docker Hub](https://img.shields.io/badge/Docker_Hub-eaglewings6-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/u/eaglewings6)
[![Portfolio](https://img.shields.io/badge/Portfolio-ops--run.lovable.app-6366f1?style=for-the-badge)](https://ops-run.lovable.app)

**Previous Projects in This Series:**

| # | Project | Repo |
|---|---------|------|
| 1 | AWS IAM Multi-Account Setup | [github.com/Eaglewings966/aws-iam-multi-account-setup](https://github.com/Eaglewings966/aws-iam-multi-account-setup) |
| 2 | GitHub Actions CI/CD Pipeline | [github.com/Eaglewings966/github-actions-cicd-pipeline](https://github.com/Eaglewings966/github-actions-cicd-pipeline) |
| 3 | Kubernetes EKS Deployment | [github.com/Eaglewings966/eks-kubernetes-deployment](https://github.com/Eaglewings966/eks-kubernetes-deployment) |
| 4 | GitOps Platform with Argo CD | **This repository** |
| 5 | AWS Cost Optimization | Coming soon |

</div>
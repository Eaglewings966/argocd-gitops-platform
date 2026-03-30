<div align="center">

# Production-Grade GitOps Platform on AWS EKS Fargate

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

**A production-grade GitOps platform that eliminates configuration drift,
enforces Git as the single source of truth, and makes bad deployments
architecturally impossible through progressive canary delivery.**

[📖 Full Technical Article](https://emmanuelubani.hashnode.dev) •
[💼 LinkedIn](https://linkedin.com/in/ubaniemmanuel) •
[🐙 GitHub](https://github.com/Eaglewings966) •
[🌐 Portfolio](https://ops-run.lovable.app)

</div>

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [Business Impact](#business-impact)
- [Architecture Overview](#architecture-overview)
- [Architecture Decisions](#architecture-decisions)
- [DevOps Toolchain](#devops-toolchain)
- [Project Structure](#project-structure)
- [Security Implementation](#security-implementation)
- [Prerequisites](#prerequisites)
- [Deployment](#deployment)
- [GitOps Flow](#gitops-flow)
- [Production Considerations](#production-considerations)
- [Key Lessons Learned](#key-lessons-learned)
- [Destroy Everything](#destroy-everything)
- [Author](#author)

---

## Problem Statement

Engineering teams operating Kubernetes at scale without a
structured GitOps delivery model accumulate four compounding
failure patterns. Configuration drift accumulates silently
between Git and the running cluster state until an incident
reveals the divergence. Deployments are manual kubectl apply
operations with no audit trail, no rollback path, and no
traffic control during transitions. When a bad release ships,
it hits 100% of users simultaneously before any health signal
exists. And when incidents happen, recovery is manual,
undocumented, and frequently amplifies the damage before
it reduces it.

This platform addresses all four failure patterns in a single
coherent architecture. It enforces Git as the authoritative
source of cluster truth, gates every release behind progressive
canary traffic steps with automated rollback, and closes the
delivery loop through GitHub Actions on every push to main.
The entire platform runs on AWS Fargate, eliminating EC2 node
lifecycle management from the operational burden entirely.

---

## Business Impact

| Metric | Before GitOps | After GitOps |
|--------|--------------|--------------|
| Configuration drift incidents | Frequent, undetected | Automatically corrected within 3 minutes |
| Deployment audit trail | None | Full Git history with author, timestamp, diff |
| Bad release blast radius | 100% of users immediately | Maximum 20% during canary step 1 |
| Manual rollback time | 15 to 45 minutes | Automatic, under 60 seconds |
| Deployment frequency risk | High — manual ops error-prone | Low — Git push triggers automated pipeline |
| On-call incidents from bad deploys | Reactive, no prevention | Prevented at canary stage before full rollout |

---

## Architecture Overview
```
┌──────────────────────────────────────────────────────────────────────┐
│                        DELIVERY PIPELINE                             │
│                                                                      │
│  Engineer pushes to main branch                                      │
│          │                                                           │
│          ▼                                                           │
│  GitHub Actions — gitops-sync.yml                                   │
│  Triggers argocd app sync immediately on push                       │
│          │                                                           │
│          ▼                                                           │
│  Argo CD reconciliation engine                                      │
│  Compares Git state to cluster state                                │
│  Detects diff, syncs child applications                             │
└─────────────────────────────┬────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        AWS us-east-1                                 │
│                                                                      │
│  VPC — eksctl managed                                               │
│  ├── Public Subnets  — NAT Gateway outbound egress                  │
│  └── Private Subnets — all Fargate pod compute                      │
│                                                                      │
│  EKS Cluster: emmanuel-gitops — Kubernetes 1.29                     │
│  Compute model: 100% AWS Fargate — zero EC2 nodes                   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  argocd namespace — Fargate profile: fp-argocd                │  │
│  │                                                                │  │
│  │  Argo CD Server                                               │  │
│  │  root-app ──watches──► argocd/apps/ in GitHub repo           │  │
│  │      ├──► devops-demo-app     (owns k8s/ manifests)          │  │
│  │      └──► argo-rollouts-config (owns rollout config)         │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  argo-rollouts namespace — Fargate profile: fp-argo-rollouts  │  │
│  │                                                                │  │
│  │  Argo Rollouts Controller                                     │  │
│  │  Manages canary traffic: 20% → 50% → 100%                    │  │
│  │  Automatic rollback on health check failure                   │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  devops-demo namespace — Fargate profile: fp-devops-demo      │  │
│  │                                                                │  │
│  │  Rollout: devops-demo-rollout                                 │  │
│  │  Image: eaglewings6/devops-demo-app:latest                    │  │
│  │  Replicas: 2 desired / 2 current / 2 available               │  │
│  │                                                                │  │
│  │  devops-demo-stable (ClusterIP) ── stable pod traffic        │  │
│  │  devops-demo-canary (ClusterIP) ── canary pod traffic        │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Local access: kubectl port-forward svc/argocd-server               │
│                -n argocd 8080:80                                     │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Architecture Decisions

**Why App of Apps over individual application registration**
Registering applications individually in Argo CD creates a direct
dependency on the Argo CD server for every new service onboarding.
App of Apps delegates application lifecycle entirely to Git.
A new service enters the platform by adding one YAML file and pushing.
No one touches the Argo CD server.

**Why Fargate over EC2 node groups**
Fargate eliminates AMI versioning, cluster autoscaler configuration,
node drain sequences, and capacity planning for worker node pools.
The trade-offs are higher per-pod cost, slower cold start, and
private-subnet-only networking. For a GitOps control plane, those
trade-offs are acceptable. Fargate also bypasses EC2 Fleet Request
quotas entirely, which blocks provisioning on new AWS accounts.

**Why Argo Rollouts over Kubernetes rolling updates**
A standard Deployment rolling update provides zero traffic control
during the transition. Argo Rollouts introduces weighted traffic steps
backed by separate stable and canary ClusterIP services. The rollout
controller owns the traffic distribution. Any step can trigger
automatic rollback based on health check failure, removing the
need for manual intervention during a bad release.

**Why Terraform Helm provider over manual helm install**
A manual helm install is not reproducible, not version-controlled,
and produces no infrastructure state. The Terraform Helm provider
makes Argo CD a first-class infrastructure resource that appears
in terraform plan, can be updated via apply, and is destroyed
cleanly via destroy. It also enables declarative resource request
configuration on every Argo CD subchart component, which is
mandatory for Fargate scheduling.

---

## DevOps Toolchain

| Tool | Version | Purpose |
|------|---------|---------|
| eksctl | 0.220.0 | EKS Fargate cluster and profile provisioning |
| AWS EKS | 1.29 | Managed Kubernetes control plane |
| AWS Fargate | Latest | Serverless pod compute — zero EC2 nodes |
| Terraform | 1.5+ | Namespace and Helm release lifecycle |
| Helm | 3.x | Argo CD and Argo Rollouts installation |
| Argo CD | 2.9 | GitOps reconciliation and self-healing |
| Argo Rollouts | 1.6 | Progressive canary delivery with auto-rollback |
| GitHub Actions | Latest | GitOps sync trigger on push to main |
| kubectl | Latest | Cluster interaction and port-forwarding |
| Docker Hub | Latest | eaglewings6/devops-demo-app:latest |

---

## Project Structure
```
argocd-gitops-platform/
│
├── .github/
│   └── workflows/
│       └── gitops-sync.yml        # Triggers Argo CD sync on push to main
│
├── terraform/
│   ├── main.tf                    # Argo CD + Argo Rollouts Helm releases
│   ├── variables.tf               # Cluster name, namespaces, chart versions
│   ├── outputs.tf                 # Access commands and destroy instructions
│   └── versions.tf                # Provider version constraints
│
├── argocd/
│   └── apps/
│       ├── root-app.yaml          # Parent app — watches argocd/apps/ in Git
│       ├── devops-demo-app.yaml   # Child app — deploys k8s/ manifests
│       └── argo-rollouts-app.yaml # Child app — manages rollout configuration
│
├── k8s/
│   ├── namespace.yaml             # devops-demo namespace with GitOps labels
│   ├── rollout.yaml               # Argo Rollout — 20/50/100 canary strategy
│   └── service.yaml               # Stable and canary ClusterIP services
│
├── .gitignore                     # Excludes tfstate, tfvars, .terraform/
└── README.md
```

---

## Security Implementation

**Least privilege IAM roles**
eksctl creates dedicated IAM roles for the EKS control plane and
Fargate execution. No wildcard permissions. No shared roles between
the cluster and application workloads. Each role carries only the
policies required for its specific function.

**No secrets in Git**
The .gitignore excludes terraform.tfvars, all .tfstate files, .env
files, and kubeconfig files. GitHub Actions secrets store the Argo CD
server address and authentication token. No credentials appear in
any committed file.

**Self-healing as a security control**
Argo CD selfHeal: true automatically reverts any manual cluster
modification that diverges from Git state. This prevents
configuration tampering from persisting in the cluster, whether
accidental or intentional, beyond a three-minute reconciliation window.

**Fargate isolation**
Each pod runs in an isolated microVM with its own network namespace.
There is no shared node filesystem or shared node network stack.
A compromised pod cannot read the filesystem or network traffic
of another pod on the same underlying hardware through a shared
node path.

**Production security additions required**
For a production deployment, this platform would additionally require
IRSA for pod-level AWS identity, External Secrets Operator with
AWS Secrets Manager for secret rotation, Argo CD SSO via Dex for
user-level audit trails, and container image scanning integrated
into the GitHub Actions pipeline before the sync step.

---

## Prerequisites

| Tool | Version | Verify |
|------|---------|--------|
| AWS CLI | v2.x | `aws --version` |
| eksctl | v0.220.0 | `eksctl version` |
| Terraform | v1.5+ | `terraform --version` |
| kubectl | Latest | `kubectl version --client` |
| Helm | v3.x | `helm version` |
| Argo CD CLI | Latest | `argocd version --client` |

> This project uses Fargate exclusively.
> No EC2 quota increases required.
> External Argo CD access uses kubectl port-forward.
> Full GitHub Actions automation requires a network-reachable
> Argo CD endpoint via ALB Controller.

---

## Deployment

### Phase 1 — EKS Fargate Cluster
```bash
eksctl create cluster \
  --name emmanuel-gitops \
  --region us-east-1 \
  --fargate

aws eks update-kubeconfig \
  --region us-east-1 \
  --name emmanuel-gitops
```

> kubectl get nodes returns nothing on Fargate. This is correct.
> Fargate provisions compute invisibly per pod.

---

### Phase 2 — Fargate Profiles
```bash
for ns in argocd argo-rollouts devops-demo; do
  eksctl create fargateprofile \
    --cluster emmanuel-gitops \
    --region us-east-1 \
    --name fp-${ns} \
    --namespace ${ns}
done

eksctl get fargateprofile \
  --cluster emmanuel-gitops \
  --region us-east-1
```

> Every namespace running pods requires a matching Fargate profile.
> Pods in a namespace without a profile stay in Pending state
> indefinitely with no error output.

---

### Phase 3 — Argo CD and Argo Rollouts via Terraform
```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply --auto-approve

kubectl get pods -n argocd
kubectl get pods -n argo-rollouts
```

> Fargate pod startup is 3 to 5 minutes slower than EC2.
> AWS provisions compute per pod. Allow time before troubleshooting.

---

### Phase 4 — Root App Deployment
```bash
# Get Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo

# Port-forward for UI access
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Open http://localhost:8080

# Push to GitHub first — Argo CD reads from the remote repo
git add .
git commit -m "feat: production GitOps platform with canary delivery"
git push origin main

# Deploy root application
kubectl apply -f argocd/apps/root-app.yaml

# Verify child apps registered
argocd app list --insecure --server localhost:8080
```

> Port-forward on Fargate drops intermittently due to network
> namespace isolation per pod. Restart port-forward when it drops.
> This is a known Fargate limitation — see Production Considerations.

---

### Phase 5 — Canary Rollout Verification
```bash
# Install Argo Rollouts plugin
curl -LO \
  https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Watch live rollout
kubectl argo rollouts get rollout devops-demo-rollout \
  -n devops-demo --watch

# Open Argo Rollouts dashboard
kubectl argo rollouts dashboard &
# Open http://localhost:3100
```

---

## GitOps Flow
```
Developer pushes to main
        │
        ▼
GitHub Actions fires — gitops-sync.yml
        │
        ▼
argocd app sync root-app (hard refresh)
        │
        ▼
Argo CD reconciles argocd/apps/ against cluster
        │
        ▼
devops-demo-app sync triggers Argo Rollouts
        │
        ▼
Step 1 — 20% canary traffic, 60s pause
        │
Health check pass ──► Step 2 — 50%, 60s pause
        │
Health check pass ──► Step 3 — 100% promotion
        │
Health check FAIL at any step
        │
        ▼
Automatic rollback — 100% stable
Zero manual intervention required
```

---

## Production Considerations

| Gap | Current State | Production Solution |
|-----|--------------|---------------------|
| Argo CD server exposure | kubectl port-forward | AWS Load Balancer Controller with ALB and ACM |
| GitHub Actions sync loop | Requires stable endpoint | ALB endpoint enables full CI/CD automation |
| Pod-level AWS identity | Fargate execution role | IRSA with scoped per-workload IAM roles |
| Secret management | Kubernetes Secrets | External Secrets Operator with AWS Secrets Manager |
| Argo CD access control | Single admin credential | Dex SSO with GitHub or Okta OIDC |
| Multi-cluster support | Single cluster | Hub-and-spoke Argo CD with downstream cluster registration |
| Container image security | No scanning | Trivy scan in GitHub Actions before sync step |

---

## Key Lessons Learned

**Fargate port-forward instability is architectural**
Port-forward drops more frequently on Fargate than on EC2 clusters.
This is caused by Fargate's per-pod network namespace isolation.
There is no shared node network stack for the tunnel to anchor to.
The production solution is ALB Controller. The development workaround
is to restart port-forward when the session drops.

**Every Fargate namespace requires an explicit profile**
The default eksctl Fargate profile covers kube-system and default
only. All other namespaces require a dedicated profile. A missing
profile produces silent Pending state with zero error output.
Create profiles before deploying workloads, not after.

**Fargate resource requests are a binary scheduling requirement**
On EC2, missing resource requests result in best-effort scheduling.
On Fargate, missing requests at or above the minimum thresholds
result in the pod never scheduling. This applies to every Argo CD
subchart component. Set requests on all of them or none will run.

**Push before apply is a hard sequencing rule**
Argo CD reads from the Git remote, not the local filesystem.
Applying the root application before pushing manifests results
in ComparisonError. In automated pipelines this is enforced by
the pipeline. In manual deployments it must be enforced by discipline.

**Self-healing changes how you think about cluster authority**
The first time Argo CD reverts a manual change you made to the
cluster, it feels wrong. It is not wrong. It is working correctly.
If a change needs to be made, it goes into Git first. That discipline
is what makes GitOps operationally reliable at scale.

**Partial automation is still documented architecture**
The GitHub Actions GitOps loop requires a network-reachable Argo CD
endpoint to execute. That endpoint does not exist in this environment
without ALB Controller. The workflow is committed, correct, and
ready the moment the endpoint exists. Documenting the gap and the
path to close it is part of the engineering work.

---

## Destroy Everything

Run in this exact order to prevent orphaned AWS resources:
```bash
# Remove Argo CD application resources first
kubectl delete application --all -n argocd

# Remove workload namespaces
kubectl delete namespace devops-demo \
  argo-rollouts argocd --ignore-not-found=true

# Destroy Terraform-managed resources
cd terraform && terraform destroy --auto-approve

# Delete the EKS Fargate cluster and all eksctl-managed resources
eksctl delete cluster \
  --name emmanuel-gitops \
  --region us-east-1
```

Verify in AWS console that EKS cluster, Fargate profiles, VPC,
NAT Gateway, and IAM roles are fully removed.
Total spend for this project: approximately $5.

---

## Author

<div align="center">

**Emmanuel Ubani**
Cloud and DevOps Engineer — Lagos, Nigeria

*From zoo volunteer to Cloud and DevOps Engineer.*
*Building production-grade infrastructure in public.*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-ubaniemmanuel-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/ubaniemmanuel)
[![GitHub](https://img.shields.io/badge/GitHub-Eaglewings966-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Eaglewings966)
[![Hashnode](https://img.shields.io/badge/Hashnode-emmanuelubani-2962FF?style=for-the-badge&logo=hashnode&logoColor=white)](https://emmanuelubani.hashnode.dev)
[![Medium](https://img.shields.io/badge/Medium-emmaubani966-000000?style=for-the-badge&logo=medium&logoColor=white)](https://medium.com/@emmaubani966)
[![Docker Hub](https://img.shields.io/badge/Docker_Hub-eaglewings6-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/u/eaglewings6)
[![Portfolio](https://img.shields.io/badge/Portfolio-ops--run.lovable.app-6366f1?style=for-the-badge)](https://ops-run.lovable.app)

| # | Project | Repository |
|---|---------|------------|
| 1 | AWS IAM Multi-Account Setup | [aws-iam-multi-account-setup](https://github.com/Eaglewings966/aws-iam-multi-account-setup) |
| 2 | GitHub Actions CI/CD Pipeline | [github-actions-cicd-pipeline](https://github.com/Eaglewings966/github-actions-cicd-pipeline) |
| 3 | Kubernetes EKS Deployment | [eks-kubernetes-deployment](https://github.com/Eaglewings966/eks-kubernetes-deployment) |
| 4 | GitOps Platform with Argo CD | This repository |
| 5 | AWS Cost Optimization | Coming soon |

</div>
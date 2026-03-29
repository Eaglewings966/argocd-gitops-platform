# -------------------------------------------------------
# Data sources — reads the cluster eksctl already created
# -------------------------------------------------------
data "aws_eks_cluster" "main" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = var.cluster_name
}

# -------------------------------------------------------
# Providers
# -------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.main.certificate_authority[0].data
  )
  token = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.main.certificate_authority[0].data
    )
    token = data.aws_eks_cluster_auth.main.token
  }
}

# -------------------------------------------------------
# Namespaces
# -------------------------------------------------------
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "project"                      = "gitops-platform"
    }
  }
}

resource "kubernetes_namespace" "argo_rollouts" {
  metadata {
    name = var.argo_rollouts_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "project"                      = "gitops-platform"
    }
  }
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "project"                      = "gitops-platform"
    }
  }
}

# -------------------------------------------------------
# Argo CD — installed via Helm
# Fargate requires explicit resource requests on every pod
# -------------------------------------------------------
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  timeout    = 600

  # Run in insecure mode — safe for port-forward access
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  # Fargate minimum resource requests — non-negotiable
  set {
    name  = "server.resources.requests.cpu"
    value = "250m"
  }
  set {
    name  = "server.resources.requests.memory"
    value = "512Mi"
  }
  set {
    name  = "controller.resources.requests.cpu"
    value = "250m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "512Mi"
  }
  set {
    name  = "repoServer.resources.requests.cpu"
    value = "250m"
  }
  set {
    name  = "repoServer.resources.requests.memory"
    value = "512Mi"
  }
  set {
    name  = "applicationSet.resources.requests.cpu"
    value = "250m"
  }
  set {
    name  = "applicationSet.resources.requests.memory"
    value = "512Mi"
  }
  set {
    name  = "notifications.resources.requests.cpu"
    value = "250m"
  }
  set {
    name  = "notifications.resources.requests.memory"
    value = "512Mi"
  }
  set {
    name  = "redis.resources.requests.cpu"
    value = "250m"
  }
  set {
    name  = "redis.resources.requests.memory"
    value = "512Mi"
  }

  depends_on = [kubernetes_namespace.argocd]
}

# -------------------------------------------------------
# Argo Rollouts — installed via Helm
# -------------------------------------------------------
resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = var.argo_rollouts_chart_version
  namespace  = kubernetes_namespace.argo_rollouts.metadata[0].name
  timeout    = 300

  set {
    name  = "controller.resources.requests.cpu"
    value = "250m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "512Mi"
  }
  set {
    name  = "dashboard.enabled"
    value = "true"
  }
  set {
    name  = "dashboard.resources.requests.cpu"
    value = "250m"
  }
  set {
    name  = "dashboard.resources.requests.memory"
    value = "512Mi"
  }

  depends_on = [kubernetes_namespace.argo_rollouts]
}
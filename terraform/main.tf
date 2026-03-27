provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name                                        = "${var.project_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    ManagedBy                                   = "terraform"
    Project                                     = var.project_name
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.project_name}-igw"
    ManagedBy = "terraform"
    Project   = var.project_name
  }
}

# --- Public Subnet A ---
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-public-a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    ManagedBy                                   = "terraform"
    Project                                     = var.project_name
  }
}

# --- Public Subnet B ---
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-public-b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    ManagedBy                                   = "terraform"
    Project                                     = var.project_name
  }
}

# --- Route Table ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name      = "${var.project_name}-public-rt"
    ManagedBy = "terraform"
    Project   = var.project_name
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# --- IAM Role for EKS Cluster ---
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = {
    ManagedBy = "terraform"
    Project   = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# --- IAM Role for Node Group ---
resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    ManagedBy = "terraform"
    Project   = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids             = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    endpoint_public_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name      = var.cluster_name
    ManagedBy = "terraform"
    Project   = var.project_name
  }
}

# --- EKS Node Group ---
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = var.desired_nodes
    min_size     = var.min_nodes
    max_size     = var.max_nodes
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry
  ]

  tags = {
    Name      = "${var.project_name}-nodes"
    ManagedBy = "terraform"
    Project   = var.project_name
  }
}

# --- Argo CD Namespace ---
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  depends_on = [aws_eks_node_group.main]
}

# --- Argo CD via Helm ---
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  timeout    = 600

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  depends_on = [kubernetes_namespace.argocd]
}

# --- Argo Rollouts Namespace ---
resource "kubernetes_namespace" "argo_rollouts" {
  metadata {
    name = "argo-rollouts"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  depends_on = [aws_eks_node_group.main]
}

# --- Argo Rollouts via Helm ---
resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = var.argo_rollouts_chart_version
  namespace  = kubernetes_namespace.argo_rollouts.metadata[0].name
  timeout    = 300

  set {
    name  = "dashboard.enabled"
    value = "true"
  }

  depends_on = [kubernetes_namespace.argo_rollouts]
}
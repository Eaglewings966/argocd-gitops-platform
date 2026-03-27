variable "aws_region" {
  description = "AWS region where all resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for naming all resources in this project"
  type        = string
  default     = "emmanuel-gitops"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "emmanuel-gitops-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "desired_nodes" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_nodes" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "argocd_namespace" {
  description = "Kubernetes namespace where Argo CD will be installed"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Helm chart version for Argo CD"
  type        = string
  default     = "5.53.14"
}

variable "argo_rollouts_chart_version" {
  description = "Helm chart version for Argo Rollouts"
  type        = string
  default     = "2.34.3"
}
variable "aws_region" {
  description = "AWS region where the EKS cluster is deployed"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS Fargate cluster created by eksctl"
  type        = string
  default     = "emmanuel-gitops"
}

variable "argocd_namespace" {
  description = "Kubernetes namespace where Argo CD is installed"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Helm chart version for Argo CD"
  type        = string
  default     = "5.53.14"
}

variable "argo_rollouts_namespace" {
  description = "Kubernetes namespace where Argo Rollouts is installed"
  type        = string
  default     = "argo-rollouts"
}

variable "argo_rollouts_chart_version" {
  description = "Helm chart version for Argo Rollouts"
  type        = string
  default     = "2.34.3"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the demo application"
  type        = string
  default     = "devops-demo"
}
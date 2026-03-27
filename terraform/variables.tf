variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "emmanuel-gitops"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "emmanuel-gitops"
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "app_namespace" {
  description = "Namespace for the application"
  type        = string
  default     = "devops-demo"
}

variable "rollouts_namespace" {
  description = "Namespace for Argo Rollouts"
  type        = string
  default     = "argo-rollouts"
}
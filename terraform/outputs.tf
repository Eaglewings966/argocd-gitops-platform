output "cluster_name" {
  description = "EKS Fargate cluster name"
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = data.aws_eks_cluster.main.endpoint
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "get_argocd_password" {
  description = "Command to retrieve the Argo CD initial admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_port_forward" {
  description = "Command to access Argo CD UI locally"
  value       = "kubectl port-forward svc/argocd-server -n argocd 8080:80"
}

output "argocd_ui_url" {
  description = "Local URL to access Argo CD after port-forward"
  value       = "http://localhost:8080"
}

output "rollout_watch_command" {
  description = "Command to watch canary rollout in real time"
  value       = "kubectl argo rollouts get rollout devops-demo-rollout -n devops-demo --watch"
}

output "destroy_cluster_command" {
  description = "Command to destroy the entire EKS Fargate cluster"
  value       = "eksctl delete cluster --name ${var.cluster_name} --region ${var.aws_region}"
}
output "cluster_name" {
  description = "EKS cluster name"
  value       = var.cluster_name
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = var.argocd_namespace
}

output "argocd_access_command" {
  description = "Command to access Argo CD UI"
  value       = "kubectl port-forward svc/argocd-server -n argocd 8080:80"
}

output "argocd_password_command" {
  description = "Command to get Argo CD initial admin password"
  value       = "kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode"
}
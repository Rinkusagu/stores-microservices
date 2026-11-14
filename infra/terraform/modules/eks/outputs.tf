output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint URL for the Kubernetes API server."
  value       = aws_eks_cluster.this.endpoint
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN to annotate the cluster-autoscaler service account."
  value       = aws_iam_role.cluster_autoscaler.arn
}
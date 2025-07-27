output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_group_id" {
  description = "ID of the EKS node group"
  value       = aws_eks_node_group.main.id
}

output "cluster_security_group_id" {
  description = "AWS-managed security group ID attached to EKS worker nodes"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "app_full_access_role_arn" {
  description = "ARN of the IAM role that provides full access to AWS services for applications"
  value       = aws_iam_role.app_full_access.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider - used by all IRSA roles"
  value       = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider - used in role trust policies"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "metrics_server_addon_arn" {
  description = "ARN of the metrics server EKS add-on"
  value       = aws_eks_addon.metrics_server.arn
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.main.arn
}

# Fargate outputs
output "fargate_pod_execution_role_arn" {
  description = "ARN of the Fargate pod execution role"
  value       = var.enable_fargate ? aws_iam_role.fargate_pod_execution_role[0].arn : null
}

output "fargate_profiles" {
  description = "Map of Fargate profile names and ARNs"
  value = var.enable_fargate ? {
    for k, v in aws_eks_fargate_profile.profiles : k => {
      arn  = v.arn
      name = v.fargate_profile_name
    }
  } : {}
}

# FluentBit logging outputs
output "fluent_bit_role_arn" {
  description = "ARN of the FluentBit IAM role for IRSA"
  value       = var.enable_cloudwatch_logging ? aws_iam_role.fluent_bit[0].arn : null
}

output "logging_setup_note" {
  description = "Note about logging setup for Kubernetes 1.33"
  value       = var.enable_cloudwatch_logging ? "FluentBit IAM role created. Deploy using helm/charts/fluentbit/deploy.sh" : "CloudWatch logging disabled"
}

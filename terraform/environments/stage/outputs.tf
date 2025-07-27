output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# ECR outputs
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = var.deploy_ecr ? module.ecr[0].repository_urls : null
}

# Redis outputs
output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = var.deploy_redis ? module.redis[0].redis_endpoint : null
}

output "redis_port" {
  description = "Redis port"
  value       = var.deploy_redis ? module.redis[0].redis_port : null
}

# EKS outputs
output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.deploy_eks ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = var.deploy_eks ? module.eks[0].cluster_name : null
}

output "eks_config_command" {
  description = "Command to configure kubectl"
  value       = var.deploy_eks ? "aws eks update-kubeconfig --region ${var.region} --name ${module.eks[0].cluster_name}" : "EKS cluster not deployed"
}

# CI/CD Outputs
output "ci_user_name" {
  description = "Name of the IAM user for CI to push to ECR"
  value       = module.ci_cd.ci_user_name
}

output "ci_access_key_id" {
  description = "Access key ID for the CI user"
  value       = module.ci_cd.ci_access_key_id
  sensitive   = true
}

output "ci_secret_access_key" {
  description = "Secret access key for the CI user"
  value       = module.ci_cd.ci_secret_access_key
  sensitive   = true
}

output "cd_user_name" {
  description = "Name of the IAM user for CD to deploy to EKS"
  value       = module.ci_cd.cd_user_name
}

output "cd_access_key_id" {
  description = "Access key ID for the CD user"
  value       = module.ci_cd.cd_access_key_id
  sensitive   = true
}

output "cd_secret_access_key" {
  description = "Secret access key for the CD user"
  value       = module.ci_cd.cd_secret_access_key
  sensitive   = true
}

# ALB Controller outputs (when deployed)
output "alb_controller_helm_release_name" {
  description = "Name of the ALB Controller Helm release"
  value       = var.deploy_eks && var.deploy_alb_controller ? module.alb_controller[0].helm_release_name : ""
}

# ALB Security Group
output "alb_security_group_id" {
  description = "ID of the ALB security group (use in ingress annotations)"
  value       = var.deploy_eks && var.deploy_alb_controller ? module.alb_controller[0].alb_security_group_id : ""
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = var.enable_ssl_certificate ? module.ssl_certificate[0].certificate_arn : ""
}

output "ssl_certificate_status" {
  description = "Status of the SSL certificate"
  value       = var.enable_ssl_certificate ? module.ssl_certificate[0].certificate_status : ""
}

output "ssl_certificate_domain_name" {
  description = "Domain name of the SSL certificate"
  value       = var.enable_ssl_certificate ? module.ssl_certificate[0].certificate_domain_name : ""
}

output "ssl_certificate_validation_records" {
  description = "DNS validation records for the SSL certificate"
  value       = var.enable_ssl_certificate ? module.ssl_certificate[0].validation_records : {}
}

output "ssl_certificate_validation_records_csv" {
  description = "DNS validation records in readable format for GoDaddy setup"
  value       = var.enable_ssl_certificate ? module.ssl_certificate[0].validation_records_csv : ""
}

output "alb_https_enabled" {
  description = "Whether HTTPS is enabled on ALB"
  value       = var.deploy_eks && var.deploy_alb_controller && var.enable_ssl_certificate ? module.alb_controller[0].https_enabled : false
}

output "alb_certificate_arn" {
  description = "ARN of the SSL certificate used by ALB (if enabled)"
  value       = var.enable_ssl_certificate ? module.ssl_certificate[0].certificate_arn : ""
}

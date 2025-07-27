variable "iam_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster to allow ALB traffic to reach worker nodes"
  type        = string
  default     = ""
}

variable "chart_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.13.0"
}

variable "enable_https" {
  description = "Whether to enable HTTPS support by adding port 443 security group rules"
  type        = bool
  default     = false
}

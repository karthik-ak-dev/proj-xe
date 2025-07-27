# S3 backend configuration - Terraform state is stored here
terraform {
  backend "s3" {
    bucket         = "test-xxx-stage-account-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "test-xxx-stage-account-terraform-state-locks-ddb"
  }
}

# Import provider versions from the providers module
module "providers" {
  source = "../../modules/providers"
}

# AWS provider configuration
provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"

  project_name     = var.project_name
  vpc_cidr         = var.vpc_cidr
  region           = var.region
  eks_cluster_name = "${var.project_name}-eks-cluster"
}

module "ecr" {
  count  = var.deploy_ecr ? 1 : 0
  source = "../../modules/ecr"

  project_name     = var.project_name
  repository_names = var.ecr_repository_names
  max_image_count  = var.ecr_max_image_count
  scan_on_push     = var.ecr_scan_on_push
  region           = var.region
}

module "ci_cd" {
  source = "../../modules/ci-cd"

  project_name       = var.project_name
  repository_names   = var.ecr_repository_names
  region             = var.region
  create_ci_user     = var.create_ci_user
  create_cd_user     = var.create_cd_user
  create_access_keys = var.create_access_keys
}

module "redis" {
  count  = var.deploy_redis ? 1 : 0
  source = "../../modules/redis"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  node_type          = var.redis_node_type
  node_count         = var.redis_node_count
  auth_token         = var.redis_auth_token
  engine_version     = var.redis_engine_version

  depends_on = [module.vpc]
}

module "aurora_postgres_serverless" {
  count  = var.deploy_aurora_srvless ? 1 : 0
  source = "../../modules/aurora-postgres-serverless"

  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = var.vpc_cidr
  public_subnet_ids    = module.vpc.public_subnet_ids
  allowed_external_ips = var.allowed_external_ips
  private_subnet_ids   = module.vpc.private_subnet_ids

  engine_version           = var.postgres_srvless_engine_version
  database_name            = var.postgres_srvless_database_name
  master_username          = var.postgres_srvless_master_username
  master_password          = var.postgres_srvless_master_password
  deletion_protection      = var.postgres_srvless_deletion_protection
  skip_final_snapshot      = var.postgres_srvless_skip_final_snapshot
  max_capacity             = var.postgres_srvless_max_capacity
  min_capacity             = var.postgres_srvless_min_capacity
  auto_pause               = var.postgres_srvless_auto_pause
  seconds_until_auto_pause = var.postgres_srvless_seconds_until_auto_pause
  timeout_action           = var.postgres_srvless_timeout_action
  availability_zones       = ["${var.region}a", "${var.region}b"]
  depends_on               = [module.vpc]
}

module "eks" {
  count  = var.deploy_eks ? 1 : 0
  source = "../../modules/eks"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  kubernetes_version = var.kubernetes_version
  instance_type      = var.eks_instance_type
  desired_capacity   = var.eks_desired_capacity
  max_capacity       = var.eks_max_capacity
  min_capacity       = var.eks_min_capacity

  # Fargate configuration
  enable_fargate = var.enable_fargate
  # fargate_profiles uses default values from EKS module

  depends_on = [module.vpc]
}

# Create locals for EKS outputs or empty values if EKS is not deployed
locals {
  eks_cluster_endpoint                   = var.deploy_eks ? (length(module.eks) > 0 ? module.eks[0].cluster_endpoint : "") : ""
  eks_cluster_certificate_authority_data = var.deploy_eks ? (length(module.eks) > 0 ? module.eks[0].cluster_certificate_authority_data : "") : ""
  eks_cluster_name                       = var.deploy_eks ? (length(module.eks) > 0 ? module.eks[0].cluster_name : "") : ""
}

# Phase 2: Configure Kubernetes and Helm providers for EKS-dependent resources

# Conditional Kubernetes provider configuration
provider "kubernetes" {
  host                   = local.eks_cluster_endpoint
  cluster_ca_certificate = local.eks_cluster_certificate_authority_data != "" ? base64decode(local.eks_cluster_certificate_authority_data) : null

  dynamic "exec" {
    for_each = local.eks_cluster_name != "" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
      command     = "aws"
    }
  }
}

# Conditional Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = local.eks_cluster_endpoint
    cluster_ca_certificate = local.eks_cluster_certificate_authority_data != "" ? base64decode(local.eks_cluster_certificate_authority_data) : null

    dynamic "exec" {
      for_each = local.eks_cluster_name != "" ? [1] : []
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
        command     = "aws"
      }
    }
  }
}

# Phase 3: Deploy EKS-dependent resources

# Optional: Create SSL Certificate if enabled
module "ssl_certificate" {
  count  = var.enable_ssl_certificate ? 1 : 0
  source = "../../modules/acm-certificate"

  domain_name               = var.ssl_domain_name
  subject_alternative_names = var.ssl_subject_alternative_names
  certificate_name          = "${var.project_name}-ssl-cert"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Optional: Deploy ALB controller if enabled (and if EKS is enabled)
module "alb_controller" {
  count  = var.deploy_eks && var.deploy_alb_controller ? 1 : 0
  source = "../../modules/alb-controller"

  iam_role_arn                  = module.eks[0].aws_load_balancer_controller_role_arn
  cluster_name                  = module.eks[0].cluster_name
  region                        = var.region
  vpc_id                        = module.vpc.vpc_id
  eks_cluster_security_group_id = module.eks[0].cluster_security_group_id
  enable_https                  = var.enable_alb_https

  depends_on = [module.eks, module.ssl_certificate]
}

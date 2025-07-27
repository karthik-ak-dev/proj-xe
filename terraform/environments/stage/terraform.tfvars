# Client-specific configuration
project_name = "stage-test-xxx"
region       = "us-east-2"
vpc_cidr     = "10.0.0.0/16"

# Feature flags  
deploy_ecr            = true  # Set to false to skip ECR repositories deployment
deploy_redis          = false # Set to false to skip Redis ElastiCache deployment
deploy_aurora_srvless = true  # Set to false to skip Aurora PostgreSQL Serverless deployment
deploy_eks            = true  # Set to false to skip EKS cluster deployment
deploy_alb_controller = true  # Set to false to skip ALB controller deployment

# Redis Configuration
redis_node_type  = "cache.t3.small"
redis_node_count = 1
redis_auth_token = "xxx-xxx-xxx-xyx"

# Aurora PostgreSQL Serverless Configuration
postgres_srvless_engine_version           = "16.6" # Aurora Serverless v2 supports PostgreSQL 16.x
postgres_srvless_database_name            = "postgresdb"
postgres_srvless_master_username          = "postgres"
postgres_srvless_master_password          = "xxx-xxx-xxx-xxx"
postgres_srvless_auto_pause               = true
postgres_srvless_max_capacity             = 2
postgres_srvless_min_capacity             = 0
postgres_srvless_seconds_until_auto_pause = 300
postgres_srvless_deletion_protection      = false # For stage environment, disable deletion protection
postgres_srvless_skip_final_snapshot      = true  # For stage environment, skip final snapshot on deletion

# EKS Configuration
kubernetes_version   = "1.33" # Now supported with AL2023_x86_64 AMI
eks_instance_type    = "t3.small"
eks_desired_capacity = 1
eks_max_capacity     = 4
eks_min_capacity     = 1

# Fargate Configuration
enable_fargate = true
# Note: Fargate profiles are configured as default variables in the EKS module
# Default profile matches all namespaces (*) with label: compute-type=fargate

# CI/CD Configuration
create_ci_user     = true
create_cd_user     = true
create_access_keys = true

enable_ssl_certificate        = true
ssl_domain_name               = "test-xxx.ai"
ssl_subject_alternative_names = ["*.test-xxx.ai"]
enable_alb_https              = true

# External IP access configuration for RDS
allowed_external_ips = [
  "182.75.87.122"
]

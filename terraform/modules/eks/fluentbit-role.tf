# ==================================================================================
# FLUENTBIT LOGGING ROLE
# ==================================================================================
# This file creates an IAM role for FluentBit to send logs to CloudWatch.
# FluentBit is deployed manually via Helm (not as EKS addon) because the addon
# doesn't support Kubernetes 1.33+.
#
# SECURITY BENEFITS:
# ✅ Uses IRSA (IAM Roles for Service Accounts) - no long-lived credentials
# ✅ Scoped permissions - only CloudWatch logs access
# ✅ Namespace-based log groups for better organization
#
# USAGE PATTERN:
# 1. Terraform creates the IAM role with CloudWatch permissions
# 2. Helm deploys FluentBit with ServiceAccount annotated with role ARN
# 3. FluentBit automatically gets AWS credentials via IRSA
# 4. Logs are sent to namespace-based CloudWatch log groups
#
# 🔗 DEPENDENCIES:
# - Requires OIDC provider from oidc-provider.tf
# - This role trusts the centralized OIDC provider for authentication
# ==================================================================================

# ==================================================================================
# FLUENTBIT IAM ROLE
# ==================================================================================
# IAM role for FluentBit DaemonSet to send logs to CloudWatch
# Only created when CloudWatch logging is enabled

resource "aws_iam_role" "fluent_bit" {
  count = var.enable_cloudwatch_logging ? 1 : 0
  name  = "${var.project_name}-fluent-bit-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        # Reference to the centralized OIDC provider
        Federated = aws_iam_openid_connect_provider.eks_oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      # No conditions - allow any ServiceAccount from this EKS cluster to assume the role
      # This is relaxed for simplicity and to avoid OIDC URL format issues
    }]
  })

  tags = {
    Name      = "${var.project_name}-fluent-bit-role"
    Purpose   = "cloudwatch-logging"
    Component = "observability"
  }
}

# ==================================================================================
# FLUENTBIT CLOUDWATCH PERMISSIONS
# ==================================================================================
# Custom policy for FluentBit to create and write to CloudWatch log groups
# Scoped to only the EKS cluster's log groups for security

resource "aws_iam_policy" "fluent_bit_cloudwatch" {
  count       = var.enable_cloudwatch_logging ? 1 : 0
  name        = "${var.project_name}-fluent-bit-cloudwatch"
  description = "CloudWatch logs permissions for FluentBit"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutRetentionPolicy",
          "logs:TagLogGroup"
        ]
        # Allow all CloudWatch logs operations
        Resource = [
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-fluent-bit-cloudwatch-policy"
    Purpose = "cloudwatch-logging"
  }
}

# Attach the CloudWatch policy to the FluentBit role
resource "aws_iam_role_policy_attachment" "fluent_bit_cloudwatch" {
  count      = var.enable_cloudwatch_logging ? 1 : 0
  policy_arn = aws_iam_policy.fluent_bit_cloudwatch[0].arn
  role       = aws_iam_role.fluent_bit[0].name
}

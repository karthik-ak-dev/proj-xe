#!/bin/bash

# Deploy FluentBit for EKS CloudWatch logging with namespace-based log groups
# This script deploys FluentBit as a Helm chart (not EKS addon) because
# the addon doesn't support Kubernetes 1.33+
#
# Set kubeconfig context: terraform output -raw eks_config_command | bash
# Usage: ./deploy.sh <cluster-name> <region> <fluent-bit-role-arn>
#
# Parameters:
#   cluster-name        - EKS cluster name (command: terraform state show module.eks[0].aws_eks_cluster.main | grep -E "^\s+name\s+=" | awk '{print $3}' | tr -d '"')
#   region             - AWS region (e.g., us-east-1)
#   fluent-bit-role-arn - IAM role ARN from Terraform output(command: terraform state show module.eks[0].aws_iam_role.fluent_bit[0] | grep "arn" | head -1 | awk '{print $3}' | tr -d '"')
#
# Example:
#   ./deploy.sh stage-beatly-eks-cluster us-east-1 arn:aws:iam::508153278741:role/stage-beatly-fluent-bit-role
#
# Get the role ARN from Terraform:
#   cd terraform/environments/stage && terraform output fluent_bit_role_arn

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${BLUE}$1${NC}"; }

# Check parameters
if [ $# -ne 3 ]; then
    print_error "Missing parameters. See script header for usage."
    exit 1
fi

CLUSTER_NAME=$1
REGION=$2
FLUENT_BIT_ROLE_ARN=$3

print_status "Deploying FluentBit for cluster: $CLUSTER_NAME"

# Check kubectl connection
if ! kubectl get nodes &> /dev/null; then
    print_error "Cannot connect to cluster. Run: aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
    exit 1
fi

# Add FluentBit Helm repository
print_status "Adding FluentBit Helm repository..."
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

print_status "✅ Helm repository updated"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create temporary values file with substitutions
print_status "Preparing FluentBit configuration..."
TEMP_VALUES="/tmp/fluent-bit-values-$(date +%s).yaml"

cat "$SCRIPT_DIR/values.yaml" | \
  sed "s|FLUENT_BIT_ROLE_ARN|$FLUENT_BIT_ROLE_ARN|g" | \
  sed "s|AWS_REGION_PLACEHOLDER|$REGION|g" | \
  sed "s|CLUSTER_NAME_PLACEHOLDER|$CLUSTER_NAME|g" > "$TEMP_VALUES"

print_status "✅ Configuration prepared"

# Deploy FluentBit
print_status "Deploying FluentBit to kube-system namespace..."
helm upgrade --install fluent-bit fluent/fluent-bit \
  --namespace kube-system \
  --values "$TEMP_VALUES" \
  --wait \
  --timeout 300s

# Clean up temporary file
rm "$TEMP_VALUES"

print_status "✅ FluentBit deployed successfully!"
print_status ""

# Wait for FluentBit pods to be ready
print_status "Waiting for FluentBit pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=fluent-bit -n kube-system --timeout=300s

print_status "✅ FluentBit pods are ready!"
print_status ""

# Show deployment status
print_header "Deployment Summary"
print_status "FluentBit DaemonSet deployed in kube-system namespace"
print_status "Logs will appear in CloudWatch Log Groups with pattern:"
print_status "  📁 /aws/eks/$CLUSTER_NAME/{namespace}"
print_status ""
print_status "Examples:"
print_status "  📁 /aws/eks/$CLUSTER_NAME/default"
print_status "  📁 /aws/eks/$CLUSTER_NAME/kube-system"
print_status "  📁 /aws/eks/$CLUSTER_NAME/user-service"
print_status "  📁 /aws/eks/$CLUSTER_NAME/order-service"
print_status ""
print_status "To view logs:"
print_status "1. Go to AWS Console → CloudWatch → Log groups"
print_status "2. Look for log groups starting with: /aws/eks/$CLUSTER_NAME/"
print_status ""
print_status "To check FluentBit status:"
print_status "  kubectl get pods -n kube-system -l app.kubernetes.io/name=fluent-bit"
print_status ""
print_header "🚀 Logging setup complete!"

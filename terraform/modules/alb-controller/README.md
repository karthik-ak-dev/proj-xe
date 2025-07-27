# AWS Load Balancer Controller Module

This Terraform module deploys the AWS Load Balancer Controller into an EKS cluster using Helm. The controller automatically creates and manages Application Load Balancers (ALBs) based on Kubernetes Ingress resources.

## Overview

The AWS Load Balancer Controller is a Kubernetes controller that:

- Watches for Kubernetes Service and Ingress resources
- Automatically creates corresponding AWS Application Load Balancers
- Manages the lifecycle of these load balancers
- Integrates with AWS services like ACM for SSL certificates

## Key Features

- **Automatic ALB Management**: Creates and manages ALBs based on Kubernetes Ingress resources
- **Security Group Management**: Creates proper security groups for ALB traffic
- **HTTPS Support**: Configures security group rules for HTTPS traffic (port 443)
- **IAM Roles for Service Accounts (IRSA)**: Secure AWS API access without storing credentials
- **Public Access**: Allows public internet access to your applications

## Module Inputs

| Variable                        | Type   | Default    | Description                                                     |
| ------------------------------- | ------ | ---------- | --------------------------------------------------------------- |
| `iam_role_arn`                  | string | -          | ARN of the IAM role for AWS Load Balancer Controller            |
| `cluster_name`                  | string | -          | Name of the EKS cluster                                         |
| `region`                        | string | -          | AWS region                                                      |
| `vpc_id`                        | string | -          | VPC ID where the ALB will be created                            |
| `eks_cluster_security_group_id` | string | `""`       | Security group ID of the EKS cluster                            |
| `chart_version`                 | string | `"1.13.0"` | Version of the AWS Load Balancer Controller Helm chart          |
| `enable_https`                  | bool   | `false`    | Whether to enable HTTPS support (port 443 security group rules) |

## Module Outputs

| Output                  | Description                  |
| ----------------------- | ---------------------------- |
| `helm_release_name`     | Name of the Helm release     |
| `helm_release_status`   | Status of the Helm release   |
| `alb_security_group_id` | ID of the ALB security group |
| `https_enabled`         | Whether HTTPS is enabled     |

## Usage Example

```hcl
module "alb_controller" {
  source = "./modules/alb-controller"

  iam_role_arn                  = module.eks.aws_load_balancer_controller_role_arn
  cluster_name                  = module.eks.cluster_name
  region                        = var.region
  vpc_id                        = module.vpc.vpc_id
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
  enable_https                  = true

  depends_on = [module.eks]
}
```

## SSL/TLS Certificate Configuration

**Important**: The ALB controller itself does **NOT** require certificate ARNs. SSL certificates are configured at the application level using Kubernetes Ingress annotations.

### How to Use SSL Certificates with ALB Controller

1. **Create ACM Certificate** (using the `acm-certificate` module):

```hcl
module "ssl_certificate" {
  source      = "./modules/acm-certificate"
  domain_name = "api.yourdomain.com"
  # ... other configuration
}
```

2. **Use Certificate in Kubernetes Ingress**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/cert-id
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: |
      {
        "Type": "redirect",
        "RedirectConfig": {
          "Protocol": "HTTPS",
          "Port": "443",
          "StatusCode": "HTTP_301"
        }
      }
spec:
  rules:
    - host: api.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80
```

3. **Get Certificate ARN from Terraform Output**:

```hcl
# Use this output in your Kubernetes manifests
output "certificate_arn" {
  value = module.ssl_certificate.certificate_arn
}
```

## Security Groups

The module creates an ALB security group with the following rules:

### Ingress Rules

- **HTTP (Port 80)**: Open to public (0.0.0.0/0)
- **HTTPS (Port 443)**: Open to public when `enable_https = true`

### Egress Rules

- **All Traffic**: Allows all outbound traffic

### EKS Integration

When `eks_cluster_security_group_id` is provided, the module creates a rule allowing ALL traffic from the ALB security group to the EKS cluster security group. This ensures ALB can reach pods on any port.

## Prerequisites

1. **EKS Cluster**: Must exist before deploying this module
2. **VPC with Public Subnets**: ALB requires public subnets for internet-facing load balancers
3. **IAM Role**: EKS module should create the ALB controller IAM role
4. **Kubernetes/Helm Providers**: Must be properly configured to connect to your EKS cluster

## Network Architecture

```
Internet → ALB (Public Subnets) → EKS Pods (Private Subnets)
           ↓
    Security Group Rules
    - Port 80/443 from anywhere
    - All traffic to EKS nodes
```

## Important Notes

- **Public Access**: This configuration creates internet-facing ALBs with public access
- **Certificate Management**: SSL certificates are managed separately and referenced in Ingress annotations
- **DNS Configuration**: You'll need to create DNS records pointing to the ALB DNS name
- **Cost**: ALBs incur hourly charges plus data processing fees
- **Limits**: AWS has limits on number of ALBs per region

## Troubleshooting

### Common Issues

1. **ALB Controller Pod Not Starting**

   - Check IAM role permissions
   - Verify IRSA annotation on service account
   - Check EKS cluster OIDC provider

2. **ALB Not Created for Ingress**

   - Verify ingress annotations are correct
   - Check ALB controller logs: `kubectl logs -n kube-system deployment/aws-load-balancer-controller`
   - Ensure ingress class is set to `alb`

3. **SSL Certificate Issues**
   - Verify certificate ARN in ingress annotations
   - Check certificate validation status in ACM
   - Ensure DNS records are configured correctly

### Useful Commands

```bash
# Check ALB controller status
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# View ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# List ingresses
kubectl get ingress

# Describe ingress for events
kubectl describe ingress <ingress-name>
```

## Dependencies

- **EKS Module**: Provides cluster name, IAM role, and security group ID
- **VPC Module**: Provides VPC ID for security group creation
- **Kubernetes Provider**: Must be configured to connect to EKS cluster
- **Helm Provider**: Used to deploy the controller chart

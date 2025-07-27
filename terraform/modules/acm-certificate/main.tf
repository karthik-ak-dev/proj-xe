# =====================================================================
# ACM CERTIFICATE MODULE
# =====================================================================
# This module creates ACM certificates with DNS validation.
# Perfect for external DNS providers like GoDaddy, Namecheap, etc.
#
# WORKFLOW:
# 1. Terraform creates certificate with DNS validation
# 2. Terraform outputs DNS validation records
# 3. Add DNS records to your external DNS provider (GoDaddy)
# 4. Certificate validates automatically and becomes "ISSUED"
# 5. Use certificate ARN in ALB/CloudFront/etc.
# =====================================================================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# =====================================================================
# ACM CERTIFICATE
# =====================================================================

resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method

  tags = merge(
    {
      Name      = var.certificate_name
      Domain    = var.domain_name
      ManagedBy = "terraform"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =====================================================================
# VALIDATION RECORDS OUTPUT
# =====================================================================
# These are the DNS records you need to add to your external DNS provider
# (GoDaddy, Namecheap, etc.) for certificate validation

locals {
  validation_records = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

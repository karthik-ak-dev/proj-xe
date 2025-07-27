variable "domain_name" {
  description = "Primary domain name for the ACM certificate (e.g., 'api.yourdomain.com')"
  type        = string
}

variable "subject_alternative_names" {
  description = "List of alternative domain names for the ACM certificate (e.g., ['*.yourdomain.com'])"
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Method to use for domain validation. DNS validation is recommended."
  type        = string
  default     = "DNS"
  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "Validation method must be either 'DNS' or 'EMAIL'."
  }
}

variable "certificate_name" {
  description = "Name tag for the ACM certificate"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the certificate"
  type        = map(string)
  default     = {}
}

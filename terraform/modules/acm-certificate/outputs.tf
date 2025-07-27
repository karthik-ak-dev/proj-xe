output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.main.arn
}

output "certificate_domain_name" {
  description = "Primary domain name of the certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Status of the certificate (PENDING_VALIDATION, ISSUED, etc.)"
  value       = aws_acm_certificate.main.status
}

output "validation_records" {
  description = "DNS validation records that need to be added to your DNS provider (GoDaddy)"
  value       = local.validation_records
}

output "validation_records_csv" {
  description = "DNS validation records in a readable format for easy copy-paste"
  value = join("\n", concat([
    "DNS Records to add to GoDaddy:",
    "================================"
    ], [
    for domain, record in local.validation_records :
    "Domain: ${domain}\nType: ${record.type}\nName: ${record.name}\nValue: ${record.value}\n"
  ]))
}

output "certificate_id" {
  description = "ID of the ACM certificate"
  value       = aws_acm_certificate.main.id
}

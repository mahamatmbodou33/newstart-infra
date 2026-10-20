output "zone_arn" {
  description = "ExternalDNS is only allowed to edit this zone"
  value       = data.aws_route53_zone.this.arn
}

output "certificate_arn" {
  value = aws_acm_certificate_validation.this.certificate_arn
}

output "waf_acl_arn" {
  value = var.enable_waf ? aws_wafv2_web_acl.alb[0].arn : ""
}
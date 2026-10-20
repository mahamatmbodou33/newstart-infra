# Look up your existing hosted zone (Terraform doesn't create or own it)
data "aws_route53_zone" "this" {
  name         = var.zone_name
  private_zone = false
}

# --- Certificate: *.dev.mbodou.com + dev.mbodou.com ---
resource "aws_acm_certificate" "this" {
  domain_name               = "*.${var.base_domain}"
  subject_alternative_names = [var.base_domain]
  validation_method         = "DNS"
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# DNS records that prove to ACM you own the domain
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Waits until ACM says ISSUED

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

# --- WAF (prod only): AWS managed rules + per-IP rate limit ---
// --- The WAF is attached to the ALB in the edge module. ---
resource "aws_wafv2_web_acl" "alb" {
  count = var.enable_waf ? 1 : 0
  name  = "${var.name}-alb"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = {
      AWSManagedRulesCommonRuleSet          = 10
      AWSManagedRulesKnownBadInputsRuleSet  = 20
      AWSManagedRulesAmazonIpReputationList = 30
    }
    content {
      name     = rule.key
      priority = rule.value
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = rule.key
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.key
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "rate-limit-per-ip"
    priority = 100
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-per-ip"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-alb"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

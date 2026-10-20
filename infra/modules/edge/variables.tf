variable "name" {
  type = string
}

variable "zone_name" {
  description = "Route 53 public hosted zone, e.g. mbodou.com"
  type        = string
}

variable "base_domain" {
  description = "dev: dev.mbodou.com | prod: mbodou.com"
  type        = string
}

variable "enable_waf" {
  type    = bool
  default = false
}

variable "waf_rate_limit" {
  description = "Requests per 5 minutes per IP before blocking"
  type        = number
  default     = 1000
}

variable "tags" {
  type    = map(string)
  default = {}
}

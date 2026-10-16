terraform {
  backend "s3" {
    bucket       = "k8s-portfolio-tfstate-014498647009"
    key          = "envs/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

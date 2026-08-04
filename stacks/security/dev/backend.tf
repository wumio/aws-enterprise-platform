terraform {
  backend "s3" {
    bucket = "nhs-bootstrap-s3-tfstate"
    key    = "security/dev/terraform.tfstate"
    region = "ca-central-1"
  }
}

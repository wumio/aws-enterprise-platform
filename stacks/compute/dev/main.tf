data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "nhs-bootstrap-s3-tfstate"
    key    = "dev/networking/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = "nhs-bootstrap-s3-tfstate"
    key    = "dev/security/terraform.tfstate"
    region = var.aws_region
  }
}

module "ec2_instance_role" {
  source = "../../../modules/iam/ec2-instance-role"

  name        = var.name
  environment = var.environment
}

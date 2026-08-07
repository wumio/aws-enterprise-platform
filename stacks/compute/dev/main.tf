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

module "private_ec2" {
  source = "../../../modules/compute/private-ec2"

  name                  = var.name
  environment           = var.environment
  subnet_id             = data.terraform_remote_state.networking.outputs.private_app_subnet_ids[0]
  security_group_id     = data.terraform_remote_state.security.outputs.application_security_group_id
  instance_profile_name = module.ec2_instance_role.instance_profile_name
}

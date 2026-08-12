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

data "terraform_remote_state" "compute" {
  backend = "s3"

  config = {
    bucket = "nhs-bootstrap-s3-tfstate"
    key    = "dev/compute/terraform.tfstate"
    region = var.aws_region
  }
}

module "alb" {
  source = "../../../modules/application/alb"

  name        = var.name
  environment = var.environment

  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids         = data.terraform_remote_state.networking.outputs.public_subnet_ids
  security_group_id  = data.terraform_remote_state.security.outputs.alb_security_group_id
  target_instance_id = data.terraform_remote_state.compute.outputs.private_ec2_instance_id
}

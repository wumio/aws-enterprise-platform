data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "nhs-bootstrap-s3-tfstate"
    key    = "dev/networking/terraform.tfstate"
    region = var.aws_region
  }
}

module "security_groups" {
  source = "../../../modules/security/security-groups"

  name        = var.name
  environment = var.environment
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
}

module "flow_logs" {
  source = "../../../modules/security/flow-logs"

  name              = var.name
  environment       = var.environment
  retention_in_days = 365
  vpc_id            = data.terraform_remote_state.networking.outputs.vpc_id
}

module "ssm_endpoints" {
  source = "../../../modules/security/ssm-endpoints"

  name        = var.name
  environment = var.environment

  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id

  private_subnet_cidrs = data.terraform_remote_state.networking.outputs.private_app_subnet_cidrs

  subnet_ids = data.terraform_remote_state.networking.outputs.private_app_subnet_ids
}

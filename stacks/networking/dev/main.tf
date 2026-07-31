# Instantiate the networking module
module "networking" {
  source = "../../../modules/networking"

  name        = var.name
  environment = var.environment

  vpc_cidr = var.vpc_cidr

  availability_zones = var.availability_zones

  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs

  enable_nat_gateway = true
  #single_nat_gateway = true
}

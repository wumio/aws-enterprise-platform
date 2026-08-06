output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.networking.private_app_subnet_ids
}

output "private_app_subnet_cidrs" {
  value = module.networking.private_app_subnet_cidrs
}

output "private_data_subnet_ids" {
  value = module.networking.private_data_subnet_ids
}

output "private_data_subnet_cidrs" {
  value = module.networking.private_data_subnet_cidrs
}

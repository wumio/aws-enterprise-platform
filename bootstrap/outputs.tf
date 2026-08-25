output "state_bucket_name" {
  description = "Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  description = "Terraform lock table"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "kms_key_arn" {
  description = "Terraform state encryption key"
  value       = aws_kms_key.terraform_state.arn

}

output "github_actions_terraform_role_arn" {
  description = "IAM role ARN for GitHub Actions Terraform delivery"
  value       = aws_iam_role.github_actions_terraform.arn
}

output "github_actions_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

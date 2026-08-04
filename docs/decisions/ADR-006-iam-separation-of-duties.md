ADR-006 — IAM Separation of Duties for Infrastructure Deployment

Separate Terraform deployment identity created for the project.

The Terraform deployment identity is intentionally not an IAM administrator.

A future evolution is AWS IAM Identity Center + deployment roles.

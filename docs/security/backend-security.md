
# Controls Implemented
| Control            | Implementation           |
| ------------------ | ------------------------ |
| Encryption at Rest | AWS KMS CMK              |
| Object Recovery    | S3 Versioning            |
| State Locking      | S3 Native Lockfile       |
| Transport Security | HTTPS-only bucket policy |
| Ownership          | BucketOwnerEnforced      |
| Access Control     | IAM policies             |
| Retention          | Lifecycle rules          |

# Milestone 6: Created special role Terraform can assume when deploying resources. This allows for separation of duties and better manageability while minimizing the security risk of elevating the default user account. "AssumeRole" trust policies created and applied. Also, a custom AWS CLI was created and details encoded in provider.tf to streamline deployment work without needing to switch profiles or enter tokens.

Terraform
   │
   ▼
AWS CLI profile
   │
   ▼
wterra-dev
   │
   │ sts:AssumeRole
   ▼
nhs-dev-terraform-role
   │
   └── Terraform permissions

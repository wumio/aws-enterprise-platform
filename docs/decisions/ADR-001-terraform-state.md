# Decision
Terraform state will be stored remotely using:
1. Amazon S3 for state storage
2. DynamoDB for state locking
3. AWS KMS for encryption

# Context
Terraform state contains the current infrastructure inventory and resource metadata. Local state storage creates operational and security risks in a collaborative engineering environment.

# Decision Rationale
Amazon S3 was selected because it provides:
- Durable storage
- Versioning
- Encryption support
- IAM access control
- AWS-native integration

DynamoDB was selected because it provides:
- Distributed locking
- Protection against simultaneous Terraform operations
- Native Terraform backend support
# Replaced later by current user_lockfile. This will be updated.

AWS KMS was selected because it provides:
- Customer-managed encryption keys
- Key rotation capability
- Access auditing through CloudTrail


# Alternatives Considered
Local State is not suitable for team-based infrastructure management.

While Terraform Cloud is a viable option, this project aims to demonstrate AWS-native infrastructure patterns.

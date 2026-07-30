# Checkov security requirement/flag for cross-region replication

This is another enterprise-level control.

Architecture:

Primary Region

ca-central-1

      |
      |
      v

Secondary Region

us-east-1

For Terraform state, this is a valid disaster recovery pattern.

However, implementing it requires:
- second bucket
- replication IAM role
- versioning
- KMS replication permissions
- destination encryption

This is beyond this bootstrap's current workplan, but it's a valid enterprise-level control for disaster recovery. It will be considered in a future iteration.

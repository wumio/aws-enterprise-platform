# ADR-005: Terraform State Disaster Recovery Strategy

## Status

Accepted

## Context

Terraform state is a critical control-plane dependency for the infrastructure platform.

The primary Terraform state bucket is hosted in `ca-central-1`. While S3 provides high durability within the AWS service, relying on a single regional state store leaves Terraform state exposed to a regional failure scenario.

For a production-oriented infrastructure platform, Terraform state should have a recoverable copy in a separate AWS region.

The platform therefore requires cross-region replication of Terraform state from the primary region:

- Primary: `ca-central-1`
- Disaster Recovery: `us-east-1`

The DR implementation must preserve the security properties of the primary state store, including encryption and versioning.

## Decision

Terraform state will be replicated from the primary S3 state bucket in `ca-central-1` to a dedicated DR S3 bucket in `us-east-1`.

The DR design consists of:

* A dedicated S3 bucket for replicated Terraform state
* S3 versioning enabled on both source and destination buckets
* S3 Cross-Region Replication (CRR)
* A dedicated IAM role assumed by the S3 replication service
* A dedicated customer-managed KMS key in the DR region
* KMS encryption for replicated state objects
* Replication of encrypted source objects
* Replication of object versions
* Lifecycle management for noncurrent object versions
* Public access blocking and ownership controls on the DR bucket

The replication rule applies to the Terraform state bucket without a prefix filter so that all Terraform state objects stored in the bucket are covered.

The resulting architecture is:

```text
                    Terraform State
                          |
                          v
              +-----------------------+
              | S3 State Bucket       |
              | ca-central-1          |
              | SSE-KMS               |
              | Versioning            |
              +-----------------------+
                          |
                          | S3 Cross-Region
                          | Replication
                          v
              +-----------------------+
              | S3 DR State Bucket    |
              | us-east-1             |
              | SSE-KMS               |
              | Versioning            |
              +-----------------------+
                          |
                          v
                 DR KMS Encryption
```

## Security

The replication role follows least-privilege principles.

The role is permitted to:

* Read replication configuration and list the source bucket
* Read source object versions required for replication
* Decrypt source objects using the primary KMS key
* Replicate objects, deletes, and tags to the DR bucket
* Encrypt replicated objects using the DR KMS key

The DR bucket uses a separate customer-managed KMS key from the primary state bucket.

This provides regional separation of encryption keys as well as regional separation of the replicated state data.

The DR bucket also has:

* Public access blocked
* Bucket-owner-enforced object ownership
* Versioning enabled
* Server-side encryption using AWS KMS
* Lifecycle management for noncurrent versions
* A bucket policy restricting access

## Implementation

The implementation was added to the Terraform bootstrap configuration.

The primary state bucket remains in ca-central-1.

A DR bucket is created in us-east-1:

nhs-bootstrap-s3-tfstate-dr

The primary bucket is configured with an S3 replication rule targeting the DR bucket.

The replication destination uses a dedicated KMS key:

alias/nhs-bootstrap-tfstate-dr

The replication configuration requires both source and destination KMS permissions.

The DR bucket lifecycle configuration retains noncurrent object versions for 365 days and aborts incomplete multipart uploads after 7 days.

## Validation

The implementation was runtime-validated in AWS after deployment.

The DR bucket was confirmed to contain replicated Terraform state objects for the existing platform stacks, including:

* bootstrap/dev/terraform.tfstate
* dev/application/terraform.tfstate
* dev/compute/terraform.tfstate
* dev/networking/terraform.tfstate
* dev/security/terraform.tfstate

The replicated objects were verified to use the dedicated DR KMS key in us-east-1.

The source bucket replication configuration was also verified to be enabled and configured to use the dedicated S3 replication IAM role.

The source bucket has versioning enabled, satisfying the S3 replication prerequisite.

An obsolete state object using the previous key convention:

security/dev/terraform.tfstate

was identified and removed after confirming that the active state key is:

dev/security/terraform.tfstate

## Consequences

Terraform state now has a separate regional recovery copy.

A regional failure affecting ca-central-1 no longer represents a single-region dependency for the most recent replicated Terraform state.

The design introduces additional AWS resources and operational considerations:

* Additional S3 storage
* Additional KMS key
* Additional IAM role and permissions
* S3 replication processing
* Lifecycle management
* Cross-region operational considerations

These costs are accepted because Terraform state is a foundational infrastructure dependency and the platform is intended to demonstrate production-oriented resilience patterns.

The DR bucket is a recovery copy and does not replace the primary Terraform backend during normal operations.

Future disaster recovery work may define the formal recovery procedure, including recovery point objectives, recovery time objectives, backend failover procedures, and validation of Terraform state recovery.

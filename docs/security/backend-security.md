
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

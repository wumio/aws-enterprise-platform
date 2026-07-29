# Security controls implemented to protect state file in s3

| Decision            | Reason                                        |
| ------------------- | --------------------------------------------- |
| S3 remote state     | Team collaboration and centralized management |
| KMS encryption      | Protect Terraform state data                  |
| S3 lockfile         | Modern Terraform state locking approach       |
| BucketOwnerEnforced | Eliminate ACL-based access risks              |
| 365-day retention   | Support recovery and audit requirements       |
| HTTPS-only policy   | Prevent insecure state access                 |

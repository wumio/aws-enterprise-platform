# Checkov exception register
| Check         | Resource                           | Decision                                               |
| ------------- | ---------------------------------- | ------------------------------------------------------ |
| `CKV2_AWS_5`  | ALB/App/DB SGs                     | Deferred until consuming workloads exist               |
| `CKV2_AWS_11` | VPC                                | Cross-stack flow-log implementation                    |
| `CKV2_AWS_62` | Terraform state/access-log buckets | Existing documented exception                          |
| `CKV_AWS_144` | S3 buckets                         | Covered by current DR strategy                         |
| `CKV2_AWS_19` | NAT EIP                            | Review as NAT Gateway association / scanner limitation |
| `CKV_AWS_260` | ALB HTTP                           | Revisit with ALB/HTTPS implementation                  |
| `CKV_AWS_382` | SG egress                          | Revisit with workload + SSM design                     |

# Deferred Checkov findings
The infrastructure foundation currently contains several Checkov findings that are intentionally deferred. These include public HTTP ingress for the initial ALB security group, security-group attachment checks for security groups created ahead of dependent compute/data resources, NAT Gateway EIP attachment detection, S3 cross-region replication, S3 event notifications, and VPC flow logging.

These findings are tracked as follow-up hardening items rather than blocking the foundation milestone. Where a Checkov rule does not accurately model the intended AWS architecture—for example, NAT Gateway EIP association or security groups referenced by resources provisioned in subsequent milestones—the finding will be evaluated against the actual architecture rather than remediated solely to satisfy the scanner.

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

## Deferred Checkov findings

The infrastructure foundation currently contains several Checkov findings that are intentionally deferred. These include
* public HTTP ingress for the initial ALB security group,
* security-group attachment checks for security groups created ahead of dependent compute/data resources,
* NAT Gateway EIP attachment detection,
* S3 cross-region replication,
* S3 event notifications, and
* VPC flow logging.

These findings are tracked as follow-up hardening items rather than blocking the foundation milestone.

Where a Checkov rule does not accurately model the intended AWS architecture—for example, NAT Gateway EIP association or security groups referenced by resources provisioned in subsequent milestones—the finding will be evaluated against the actual architecture rather than remediated solely to satisfy the scanner.

S3 access-log bucket cross-region replication remains deferred; Terraform state replication is implemented as part of the state DR strategy.

## Exceptions found at Terraform DR milestone

* Primary state bucket — CKV2_AWS_62 - No event notifications required.
* DR state bucket — CKV2_AWS_62 - No event notifications required.
* Access-log bucket — CKV2_AWS_62 - No event notifications required.
* DR state bucket — CKV_AWS_18 - Access logging for the DR bucket is deferred because the existing access-log destination is in the primary region. A dedicated DR-region logging architecture is outside the scope of the Terraform state DR milestone and will be addressed as part of future observability work.
* Access-log bucket — CKV_AWS_144 - Replication of the access-log bucket is outside the scope/purpose of this bootstrap DR design.

These Checkov findings concern generic S3 event notification, access logging, and cross-region replication recommendations.

The controls are intentionally not implemented because the affected buckets support Terraform bootstrap/state-management functions and there is currently no operational event consumer requiring object notifications.

The DR state bucket is already protected through cross-region encrypted replication from the primary state bucket.

Replicating the access-log bucket or introducing a separate cross-region logging architecture would add infrastructure and operational complexity without materially improving the stated Terraform state resilience objective.

# ADR-009: Private EC2 Workload and Systems Manager Administration

* **Status:** Accepted
* **Date:** 2026-08-07
* **Decision owners:** Infrastructure Engineering
* **Scope:** Develop compute foundation

## Context
The platform requires a representative application workload to validate that the networking, security, and identity foundations can support an operational EC2 workload.

Administrative access to the workload must not require exposing the instance directly to the public internet.

A traditional approach would be to assign a public IP address and permit SSH access. Although technically straightforward, this introduces an unnecessary inbound administrative attack surface and does not align with the platform's private-by-default direction.

AWS Systems Manager provides an alternative management mechanism that allows EC2 instances to be administered through AWS APIs rather than requiring inbound SSH connectivity.

The platform already provides private VPC interface endpoints for Systems Manager, allowing this management model to operate without requiring public connectivity for the workload.

## Decision
Deploy application EC2 workloads into private application subnets without public IP addresses and use AWS Systems Manager as the primary administrative access mechanism.

The workload receives an EC2 IAM instance profile containing `AmazonSSMManagedInstanceCore`.

Private VPC interface endpoints are provided for:
* Systems Manager
* Systems Manager Messages
* EC2 Messages

A dedicated security group controls access to the Systems Manager interface endpoints.

The workload itself uses the existing application security group from the security foundation.

## Architecture

```text
Private EC2
    |
    +-- EC2 IAM Instance Profile
    |       |
    |       +-- AmazonSSMManagedInstanceCore
    |
    +-- Application Security Group
    |
    +-- No Public IP
    |
    v
Private Application Subnet
    |
    v
SSM VPC Interface Endpoints
    |
    +-- SSM
    +-- SSMMessages
    +-- EC2Messages
    |
    v
AWS Systems Manager
```

## Alternatives Considered

### Public EC2 with SSH
**Rejected.**

A public IP combined with inbound SSH would expose the workload directly to the internet and introduce an unnecessary administrative entry point.

It would also require additional controls such as SSH key management, inbound access restrictions, and potentially bastion or source-IP management.

### Bastion host with SSH
**Rejected for the current scope.**

A bastion host can provide controlled administrative access to private workloads, but it introduces another infrastructure component that must itself be secured, patched, monitored, and operated.

The current workload does not require interactive SSH access, so introducing a bastion would add complexity without providing a corresponding benefit.

### Private EC2 with NAT and Systems Manager
**Considered viable.**

A private workload can communicate with AWS services through NAT gateways. However, using private Systems Manager interface endpoints provides a more explicit private connectivity model for Systems Manager and avoids making NAT the required path for management traffic.

### Private EC2 with Systems Manager VPC endpoints
**Selected.**

This provides private administrative connectivity while maintaining the workload's lack of public exposure.

It also establishes a reusable pattern for future private workloads.

## Security Considerations
The decision provides several security benefits:
* no public IP on the workload
* no inbound SSH requirement
* AWS-managed workload identity
* IAM-based authorization
* private Systems Manager connectivity
* dedicated endpoint security controls
* IMDSv2 required
* encrypted root storage

The model reduces the number of externally exposed components and centralizes administrative access through AWS Systems Manager.

## Operational Validation
The implementation was validated against the deployed development workload.

The EC2 instance was confirmed to have:
* a private IP address
* no public IP address
* the expected IAM instance profile
* a running Amazon Linux operating system

Systems Manager subsequently reported the instance as `Online`.

An AWS Systems Manager Run Command was executed successfully against the instance and returned:

```text
Status: Success
```

This confirms that the selected management architecture is operational rather than theoretical.

## Consequences

### Positive
* Workloads remain private by default.
* No inbound SSH access is required.
* Administrative access is integrated with AWS IAM and Systems Manager.
* The pattern is reusable for additional private workloads.
* The management plane can operate through private VPC connectivity.
* The architecture aligns with least-exposure principles.

### Negative
* Systems Manager endpoints introduce additional infrastructure and cost.
* Endpoint security groups must be maintained.
* Systems Manager becomes a dependency for operational access.
* Troubleshooting requires understanding the relationship between IAM, networking, endpoint configuration, and the SSM agent.

These trade-offs are considered acceptable for the platform.

## Future Considerations
As the platform evolves, the private workload pattern can be extended to:
* Launch Templates
* Auto Scaling Groups
* Application Load Balancers
* multiple application instances
* automated patching
* Systems Manager Automation
* centralized monitoring
* production workload environments

The principle of private-by-default workload placement should remain the baseline unless a specific workload has a documented requirement for direct public exposure.

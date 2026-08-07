# Private EC2 Workload

## Overview
The compute foundation now includes a private Amazon EC2 workload deployed into the application's private subnet space.

The workload is intentionally deployed without a public IP address and is administered through AWS Systems Manager (SSM). Private VPC interface endpoints provide the Systems Manager connectivity required for management without exposing the instance to the public internet for administrative access.

This establishes a private-by-default workload pattern that can be extended as additional application workloads are introduced.

## Architecture
The private workload builds on the networking, security, and identity foundations already established in the platform.

```text
                         AWS Systems Manager
                                  |
                    +-------------+-------------+
                    |             |             |
                   SSM       SSMMessages    EC2Messages
                    |             |             |
                    +-------------+-------------+
                                  |
                         Private VPC Endpoints
                                  |
                         Private Application
                              Subnet
                                  |
                         +----------------+
                         |  Private EC2   |
                         | Amazon Linux   |
                         | 2023           |
                         +----------------+
                           |            |
                    IAM Instance       Application
                       Profile             SG
                           |
              AmazonSSMManagedInstanceCore
```

The workload is connected to the existing platform foundations through Terraform remote state:

```text
Networking Stack
      |
      +-- VPC
      +-- Private application subnets
      |
      v
Security Stack
      |
      +-- Application security group
      +-- SSM endpoint security group
      +-- SSM VPC endpoints
      |
      v
Compute Stack
      |
      +-- EC2 IAM role
      +-- EC2 instance profile
      +-- Private EC2 workload
```

## Workload Configuration
The development workload is currently deployed with the following characteristics:

| Property         | Configuration              |
| ---------------- | -------------------------- |
| Workload         | Amazon EC2                 |
| Environment      | `dev`                      |
| Instance name    | `nhs-dev-private-ec2`      |
| Instance type    | `t3.micro`                 |
| Operating system | Amazon Linux 2023          |
| VPC              | `vpc-0dcda4c25a7914a87`    |
| Subnet           | Private application subnet |
| Private IP       | `10.0.11.103`              |
| Public IP        | None                       |
| Security group   | Application security group |
| IAM role         | `nhs-dev-ec2-role`         |
| Instance profile | `nhs-dev-ec2-profile`      |
| Management       | AWS Systems Manager        |
| Root volume      | 20 GB encrypted GP3        |

The Amazon Linux 2023 AMI is resolved through the AWS Systems Manager public parameter for the current regional Amazon Linux release rather than hard-coding an AMI identifier.

## Network Placement
The instance is deployed into a private application subnet provided by the networking stack.

The workload does not receive a public IPv4 address.

This provides network-level separation between externally accessible infrastructure and application workloads. Internet-facing access can be introduced later through purpose-built components such as an Application Load Balancer rather than by exposing the workload instance directly.

Note: The compute stack consumes networking information through Terraform remote state rather than recreating or independently managing the VPC and subnet resources.

## Security Controls
The workload uses the existing application security group from the security foundation.

The security group provides the workload's network policy while preserving the separation between:
* Internet-facing load balancer resources
* Application workloads
* Database resources

The current application security group allows the application traffic required by the existing foundation and permits outbound HTTPS connectivity.

No inbound SSH access is required for administrative management.

## Workload Identity
The EC2 instance receives an IAM instance profile containing the `nhs-dev-ec2-role` IAM role.

The role trusts the EC2 service and is attached to the AWS managed policy: `AmazonSSMManagedInstanceCore`

This provides the permissions required for Systems Manager-managed instance functionality.

The workload therefore receives AWS permissions through its instance identity rather than through credentials stored on the instance.

## Private Systems Manager Access
Systems Manager connectivity is provided through private VPC interface endpoints for:
* `ssm`
* `ssmmessages`
* `ec2messages`

The endpoints are deployed into the private application subnet space and protected by a dedicated security group allowing HTTPS traffic from the private subnets.

This allows the EC2 workload to communicate with Systems Manager without requiring a public IP address for management connectivity.

## Instance Hardening
The workload incorporates several baseline security controls:

### No public IP
The instance is explicitly deployed without a public IPv4 address.

### IMDSv2
The instance requires token-based access to the EC2 Instance Metadata Service: http_tokens = "required"

This reduces exposure to attacks that depend on unauthenticated metadata access.

### Encrypted storage
The root EBS volume is encrypted and uses GP3 storage.

The volume is configured for deletion when the instance is terminated.

### Monitoring
Detailed EC2 monitoring is enabled for the workload.

## Operational Validation
The workload was validated after deployment using AWS CLI and Systems Manager.

The resulting instance was confirmed to be:
* running
* located in the expected private application subnet
* assigned only a private IP address
* assigned no public IP address
* associated with the expected IAM instance profile

Systems Manager subsequently reported the instance as:
PingStatus: Online
Platform:   Amazon Linux

The SSM agent reported version `3.3.4624.0`.

An AWS Systems Manager Run Command was also executed successfully against the instance, returning: "Status: Success"

This demonstrates that the workload is not merely configured for SSM management; private Systems Manager connectivity was verified operationally.

## Terraform Integration
The compute stack consumes outputs from the networking and security stacks using Terraform remote state.

Relevant dependencies include:
Networking
  -> VPC ID
  -> Private application subnet IDs

Security
  -> Application security group ID
  -> SSM endpoint connectivity

IAM
  -> EC2 role
  -> EC2 instance profile

Compute
  -> Private EC2 workload

The stack maintains its own remote state using the established stack state-key convention.

## Current Scope
This implementation establishes a single development EC2 workload as the first private application workload.

The current scope intentionally does not include:
* Application Load Balancer resources
* Auto Scaling
* Launch Templates
* Auto Scaling Groups
* application deployment
* database deployment
* production workload configuration
* centralized observability beyond the existing platform foundation

These can be introduced as subsequent milestones.

## Future Evolution
The private EC2 pattern provides a foundation for evolving toward more production-oriented workload architecture.

Potential future extensions include:
* Launch Templates
* Auto Scaling Groups
* Application Load Balancers
* multiple application instances
* workload-specific security groups
* centralized logging and metrics
* automated patch management
* backup policies
* Systems Manager automation
* production and test environments
* CI/CD-driven infrastructure changes

The key architectural principle remains that application workloads should remain private by default, with controlled access provided through explicitly designed platform services.

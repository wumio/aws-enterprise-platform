# AWS Enterprise Platform

Production-inspired AWS infrastructure platform built with Terraform.

## Objectives

- Secure remote Terraform state
- Enterprise networking
- Infrastructure as Code
- Cloud security
- Modular architecture
- CI/CD automation
- Observability
- Disaster recovery

## Current Status

- ✅ Bootstrap infrastructure
- ✅ Remote state management
- ✅ Backend hardening
- ✅ CI/CD pipeline
- ✅ Networking stack
- ⏳ Identity stack
- ⏳ Compute stack


## Local Development

1, Install pre-commit:

pip install pre-commit
pre-commit install

2, Run all local quality checks:

pre-commit run --all-files

The repository uses pre-commit to automatically:
- Format Terraform code
- Validate Terraform configuration
- Run TFLint
- Perform basic repository hygiene checks

## Architecture
The platform is organized into independently managed Terraform stacks with explicit dependencies between infrastructure layers.

                    AWS Account
                        |
          ┌─────────────┴─────────────┐
          │                           │
     Bootstrap                  Infrastructure
          │                           │
          │                 ┌─────────┴─────────┐
          │                 │                   │
          │            Networking            Security
          │                 │                   │
          │                 │             ┌─────┴─────┐
          │                 │             │           │
          │                 │          Security     SSM
          │                 │          Groups     Endpoints
          │                 │             │           │
          │                 └─────────────┴───────────┘
          │                               │
          │                               ▼
          │                            Compute
          │                               │
          │                         EC2 IAM Role
          │                         + Instance Profile
          │
          └── Remote Terraform State

### Terraform stacks

stacks/
├── networking/
│   └── dev/
├── security/
│   └── dev/
└── compute/
    └── dev/

Each stack maintains its own Terraform state. Downstream stacks consume required values from upstream stacks through Terraform remote-state data sources.

### Stack dependencies

networking
    │
    │ VPC ID
    │ subnet IDs
    │ subnet CIDRs
    ▼
security
    │
    │ security group IDs
    │
    ▼
compute

This separates infrastructure concerns while allowing controlled dependencies between layers.

### Reusable modules
The platform uses reusable Terraform modules for major infrastructure capabilities:

modules/
├── networking/
├── security/
│   ├── security-groups/
│   ├── flow-logs/
│   └── ssm-endpoints/
└── iam/
    └── ec2-instance-role/

### Identity architecture

Terraform infrastructure changes are performed through the dedicated: nhs-dev-terraform-role

The human development IAM identity is permitted to assume this role rather than receiving infrastructure administration permissions directly.

Workloads receive separate IAM identities. The EC2 foundation provisions:

nhs-dev-ec2-role
nhs-dev-ec2-profile

with `AmazonSSMManagedInstanceCore` attached to the EC2 role.

### Private EC2 management

Systems Manager interface VPC endpoints are deployed into three private application subnets:
- SSM
- SSMMessages
- EC2Messages

This provides a private management path for EC2 workloads without requiring direct inbound SSH access.

### Current foundation

The current development environment provides:
* AWS VPC and subnet architecture Public and private subnet tiers
* NAT gateway connectivity
* Security groups for application, database, and load-balancer tiers
* VPC Flow Logs with encrypted CloudWatch logging
* Private Systems Manager VPC endpoints
* EC2 workload IAM role and instance profile
* Terraform remote-state separation between infrastructure stacks
* Dedicated Terraform execution role

# AWS Enterprise Platform

Production-inspired AWS infrastructure platform built with Terraform.

## Objectives
* Secure remote Terraform state
* Enterprise networking
* Infrastructure as Code
* Cloud security
* Modular architecture
* CI/CD automation
* Observability
* Disaster recovery

## Current Status
* ✅ Bootstrap infrastructure
* ✅ Remote state management
* ✅ Backend hardening
* ✅ CI/CD pipeline
* ✅ Networking foundation
* ✅ Security foundation
* ✅ Terraform execution identity
* ✅ EC2 workload identity
* ✅ Private EC2 compute foundation
* ✅ Private Systems Manager connectivity

## Local Development

### 1. Install pre-commit

```bash
pip install pre-commit
pre-commit install
```

### 2. Run all local quality checks

```bash
pre-commit run --all-files
```

The repository uses pre-commit to automatically:
* Format Terraform code
* Validate Terraform configuration
* Run TFLint
* Perform basic repository hygiene checks

## Architecture
The platform is organized into independently managed Terraform stacks with explicit dependencies between infrastructure layers.

```text
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
                │                 │        Security       SSM
                │                 │        Groups       Endpoints
                │                 │             │           │
                │                 └─────────────┴───────────┘
                │                               │
                │                               ▼
                │                            Compute
                │                               │
                │                     ┌─────────┴─────────┐
                │                     │                   │
                │                 EC2 IAM            Private EC2
                │                 Role/Profile         Workload
                │
                └── Remote Terraform State
```

### Terraform stacks

```text
stacks/
├── networking/
│   └── dev/
├── security/
│   └── dev/
└── compute/
    └── dev/
```

Each stack maintains its own Terraform state. Downstream stacks consume required values from upstream stacks through Terraform remote-state data sources.

### Stack dependencies

```text
networking
    │
    │ VPC ID
    │ subnet IDs
    │ subnet CIDRs
    ▼
security
    │
    │ security group IDs
    │ private SSM endpoints
    ▼
compute
    │
    │ EC2 workload
    │ EC2 IAM role/profile
    ▼
private workload
```

This separates infrastructure concerns while allowing controlled dependencies between layers.

## Reusable Modules
The platform uses reusable Terraform modules for major infrastructure capabilities:

```text
modules/
├── networking/
├── security/
│   ├── security-groups/
│   ├── flow-logs/
│   └── ssm-endpoints/
└── iam/
    └── ec2-instance-role/
```

## Identity Architecture
Terraform infrastructure changes are performed through the dedicated:

```text
nhs-dev-terraform-role
```

The human development IAM identity is permitted to assume this role rather than receiving infrastructure administration permissions directly.

Workloads receive separate IAM identities. The EC2 foundation provisions:

```text
nhs-dev-ec2-role
nhs-dev-ec2-profile
```

The EC2 role has the AWS-managed `AmazonSSMManagedInstanceCore` policy attached, providing the permissions required for Systems Manager management.

This separates:
* **Human identity** — used to authenticate and assume the Terraform execution role
* **Terraform execution identity** — used to provision infrastructure
* **Workload identity** — assigned to EC2 instances through an instance profile

## Private EC2 Management
The compute foundation provisions an Amazon Linux EC2 instance in a private application subnet.

The instance:
* Has no public IP address
* Uses the application security group
* Uses encrypted EBS storage
* Requires IMDSv2
* Receives the EC2 workload IAM role through an instance profile
* Is managed through AWS Systems Manager

Private Systems Manager connectivity is provided through VPC interface endpoints for:
* `ssm`
* `ssmmessages`
* `ec2messages`

The endpoints are deployed into the private application subnet tier, allowing the EC2 workload to communicate with Systems Manager without requiring a public IP address or direct inbound SSH access.

The workload has been validated through Systems Manager with the instance reporting an `Online` ping status.

## Current Foundation
The current development environment provides:
* AWS VPC and subnet architecture with public and private subnet tiers
* NAT gateway connectivity
* Security groups for application, database, and load-balancer tiers
* VPC Flow Logs with encrypted CloudWatch logging
* Private Systems Manager VPC endpoints
* EC2 workload IAM role and instance profile
* Private EC2 compute workload
* Encrypted EC2 root volume
* IMDSv2 enforcement
* Terraform remote-state separation between infrastructure stacks
* Dedicated Terraform execution role
* Local Terraform validation, formatting, and TFLint checks through pre-commit
* CI-based Terraform validation

## Infrastructure Management Model
The platform follows a layered infrastructure model:

```text
Bootstrap
   │
   └── Remote Terraform State
             │
             ▼
        Networking
             │
             ▼
          Security
             │
             ├── Security Groups
             ├── Flow Logs
             └── Private SSM Connectivity
             │
             ▼
          Compute
             │
             ├── EC2 IAM Role
             ├── Instance Profile
             └── Private EC2 Workload
```

Each layer is independently managed and consumes only the outputs required from upstream layers.

This provides a foundation for progressively adding production-oriented capabilities such as load balancing, application workloads, databases, monitoring, backup, disaster recovery, and automated deployment pipelines.

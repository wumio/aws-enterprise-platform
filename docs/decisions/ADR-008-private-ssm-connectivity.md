# ADR-007: Private Systems Manager Connectivity

Status: Accepted
Date: 2026-08-06
Decision Owners: Infrastructure Engineering
Scope: AWS VPC, EC2, and Systems Manager

## Context
EC2 instances deployed into private application subnets require a mechanism for operational management without exposing administrative access directly to the public internet.

Traditional SSH-based administration would require additional network exposure, such as:
- public IP addresses
- inbound TCP/22 rules
- bastion hosts
- additional key-management processes

AWS Systems Manager (SSM) provides an alternative management path that can operate through private VPC connectivity.

## Decision
The development security stack will provision AWS Systems Manager interface VPC endpoints within the private application subnets.

The following endpoints are provisioned:
- com.amazonaws.ca-central-1.ssm
- com.amazonaws.ca-central-1.ssmmessages
- com.amazonaws.ca-central-1.ec2messages

The endpoints use a dedicated security group: nhs-dev-security-ssm-endpoints-sg

The endpoint security group permits HTTPS traffic on TCP/443 from the private application subnet CIDR ranges.

The resulting architecture is:

                    AWS Region
                        |
                ┌───────┴────────┐
                │      VPC       │
                │                │
                │  Private App   │
                │    Subnets     │
                │                │
                │   ┌────────┐   │
                │   │  EC2   │   │
                │   └───┬────┘   │
                │       │        │
                │       │ HTTPS  │
                │       v        │
                │ ┌────────────┐ │
                │ │    SSM     │ │
                │ │ VPC Endpts │ │
                │ └────────────┘ │
                │                │
                └────────────────┘

## Endpoint Security
The endpoint security group uses explicit security-group rule resources.

Ingress:
Source:
10.0.11.0/24
10.0.12.0/24

Protocol:
TCP

Port:
443

Egress:
Protocol:
TCP

Port:
443

Destination:
0.0.0.0/0

The ingress restriction limits access to the endpoint interfaces from the private application subnet ranges rather than permitting unrestricted VPC access.

## Rationale
The primary objective is to provide operational access to private EC2 workloads without requiring direct inbound administrative access.

This supports a defense-in-depth model in which:

Internet
   X
   |
   X-- No direct SSH requirement
   |
Private EC2
   |
   | HTTPS
   v
SSM VPC Endpoints
   |
   v
AWS Systems Manager

The approach also avoids requiring a dedicated bastion host for basic Systems Manager administration.

## IAM Integration
Private SSM networking is combined with an EC2 workload identity.

The EC2 instance profile uses: `AmazonSSMManagedInstanceCore`

The combination provides:
EC2
 |
 +-- IAM Instance Profile
 |       |
 |       +-- nhs-dev-ec2-role
 |               |
 |               +-- AmazonSSMManagedInstanceCore
 |
 +-- Private network connectivity
         |
         +-- SSM VPC endpoints

Both identity and network connectivity are therefore required for Systems Manager management.

## Consequences

Positive
- EC2 instances can remain in private subnets.
- No public IP is required for administrative access.
- No inbound SSH rule is required for Systems Manager management.
- The SSM endpoint security group provides explicit network controls.
- EC2 authentication to Systems Manager uses IAM rather than static credentials.
- The architecture is suitable for extending toward a more fully private workload environment.

### Trade-offs
- Interface VPC endpoints incur AWS costs.
- Each endpoint creates additional networking infrastructure to manage.
- Systems Manager functionality depends on both IAM configuration and network connectivity.
- Endpoint configuration must be replicated appropriately across environments.

## Future Considerations
As additional private AWS services are introduced, the platform may add additional VPC endpoints where justified.

Future environments should evaluate:
- endpoint policies
- centralized endpoint architecture
- VPC DNS configuration
- endpoint cost optimization
- multi-AZ endpoint placement
- Systems Manager Session Manager controls
- CloudTrail auditing of management activity

The endpoint configuration should remain modular so that additional AWS services can be introduced without coupling them to the core networking module.

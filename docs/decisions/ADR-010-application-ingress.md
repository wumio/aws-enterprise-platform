# ADR-010: Application Ingress Through an Application Load Balancer

* **Status:** Accepted
* **Date:** 2026-08-11
* **Decision owners:** Infrastructure Engineering
* **Scope:** Application ingress and workload exposure

## Context

ADR-009 established the platform's private workload model by deploying application EC2 instances into private application subnets without public IP addresses and using AWS Systems Manager for administrative access.

The private EC2 workload has now been validated as an operational HTTP workload. The instance runs nginx on TCP port 80 and remains accessible for administration through AWS Systems Manager without requiring inbound SSH or direct public exposure.

The platform now requires a controlled application ingress mechanism that allows users to access the workload without exposing the underlying EC2 instance directly to the internet.

An internet-facing Application Load Balancer provides an appropriate ingress layer. It can reside in the existing public subnets while forwarding application traffic to the private workload.

## Decision

Deploy an internet-facing AWS Application Load Balancer across the existing public subnets as the application ingress layer.

The Application Load Balancer will:

* use the existing ALB security group provisioned by the security foundation
* listen for HTTP traffic on TCP port 80
* forward traffic to a target group containing the private EC2 workload
* perform HTTP health checks against the workload's `/health` endpoint
* remain separate from the private application workload

The existing application security group will continue to control workload access. HTTP traffic to the application workload is permitted only when sourced from the ALB security group.

The EC2 workload will remain in a private application subnet and will not receive a public IP address.

HTTPS termination is intentionally deferred. The existing ALB security group permits HTTPS ingress, but an HTTPS listener will be introduced as a separate enhancement alongside ACM certificate management and DNS considerations.

## Architecture

```text
                         Internet
                            |
                         TCP :80
                            |
                            v
                  +--------------------+
                  | Application Load   |
                  | Balancer           |
                  |                    |
                  | Public Subnets     |
                  +---------+----------+
                            |
                       HTTP :80
                            |
                     Target Group
                            |
                            v
                  +--------------------+
                  | Private EC2        |
                  |                    |
                  | Application SG     |
                  | nginx :80          |
                  | /health            |
                  +--------------------+
                            |
                            v
                    Private Subnet
```

The security relationship is:

```text
Internet
    |
    v
ALB Security Group
    |
    | TCP/80
    v
Application Security Group
    |
    v
Private EC2
```

Administrative access remains separate:

```text
Infrastructure Engineer
        |
        v
AWS Systems Manager
        |
        v
Private EC2
```

## Alternatives Considered

### Public EC2 with direct HTTP access

**Rejected.**

Exposing the EC2 instance directly would bypass the application ingress layer and violate the platform's private-by-default workload model.

It would also couple application access to an individual compute instance.

### Bastion host with direct access to the workload

**Rejected.**

A bastion addresses administrative access rather than application ingress and would introduce additional infrastructure that is unnecessary because Systems Manager already provides the required management capability.

### Public EC2 behind a load balancer

**Rejected.**

The EC2 workload does not require direct internet connectivity. Keeping it private reduces the externally exposed attack surface and allows the ALB to act as the controlled application boundary.

### Application Load Balancer with private EC2

**Selected.**

This provides a clear separation between public application ingress and private workload execution.

The model supports future expansion to multiple application instances and Auto Scaling without changing the fundamental security architecture.

## Security Considerations

The decision provides the following security properties:

* the EC2 workload has no public IP address
* inbound application traffic is restricted to the ALB security group
* the ALB is the only intended public application ingress point
* administrative access remains through Systems Manager
* the workload continues to use the existing application security group
* the workload does not require inbound SSH
* the ALB and workload security boundaries remain separate

The architecture therefore distinguishes between:

* **application ingress** — ALB
* **workload execution** — private EC2
* **administrative access** — Systems Manager

## Operational Validation

Before introducing the ALB, the private workload was validated independently.

The development EC2 instance was confirmed to:

* operate without a public IP address
* appear `Online` in AWS Systems Manager
* run Amazon Linux 2023
* run nginx successfully
* listen on TCP port 80
* return `OK` from `/health`
* return the expected application response from `/`
* respond successfully through its private IP address

This establishes the workload as an operational target before introducing the application ingress layer.

## Consequences

### Positive

* Application workloads remain private.
* Public application access is centralized through the ALB.
* Security groups enforce the intended traffic relationship.
* The architecture can support multiple application targets in the future.
* Target health can be monitored through ALB health checks.
* The workload remains independently manageable through Systems Manager.
* The application ingress layer is separated from compute lifecycle.

### Negative

* The ALB introduces additional infrastructure and cost.
* Public ingress remains dependent on the availability of the ALB.
* Health checks and target registration must be maintained.
* HTTPS requires additional certificate and DNS infrastructure.

These trade-offs are acceptable for the development platform and provide a realistic foundation for future production-oriented extensions.

## Future Considerations

The application ingress pattern can be extended to support:

* HTTPS termination with AWS Certificate Manager
* Route 53 DNS
* HTTP-to-HTTPS redirection
* multiple EC2 targets
* Auto Scaling Groups
* Launch Templates
* deployment automation
* centralized application logging and monitoring
* WAF integration

The private-by-default workload principle established by ADR-009 remains the baseline.

## Security Controls and Deferred Hardening
Checkov identifies several controls that are not implemented in this milestone, including HTTPS/TLS termination, HTTP-to-HTTPS redirection, WAF protection, ALB access logging, deletion protection, and HTTP header hardening.

These controls are intentionally deferred to subsequent application security and observability milestones. The current implementation uses HTTP intentionally to validate the initial ALB-to-private-workload ingress path.

# Observability Foundation

## Purpose

The observability foundation provides centralized logging for workloads running on private EC2 instances.

The initial implementation focuses on Nginx access and error logs collected by the Amazon CloudWatch Agent and delivered to Amazon CloudWatch Logs.

## Architecture

```text
                         AWS Account
                              |
                              ▼
                       Private EC2
                              |
                    ┌─────────┴─────────┐
                    │                   │
               Nginx workload      EC2 IAM Role
                    │                   │
              ┌─────┴─────┐             │
              │           │             │
         access.log   error.log         │
              │           │             │
              └─────┬─────┘             │
                    │                   │
                    ▼                   ▼
             CloudWatch Agent    CloudWatch permissions
                    │
                    ▼
             CloudWatch Log Group
          /aws/ec2/nhs-dev/nginx
                    │
             ┌──────┴──────┐
             │             │
          /access        /error

## Components

### CloudWatch Log Group

Terraform manages a dedicated log group:

/aws/ec2/nhs-dev/nginx

Log retention is configurable through the observability module.

### CloudWatch Agent

The Amazon CloudWatch Agent is installed during EC2 bootstrap.

The agent collects:
* /var/log/nginx/access.log
* /var/log/nginx/error.log

Each log type is written to a separate stream using the EC2 instance ID.

### EC2 Workload Identity

The EC2 instance receives a dedicated IAM role through its instance profile.

The role provides:

* AWS Systems Manager management permissions
* CloudWatch Agent permissions

This avoids embedding AWS credentials in the instance or bootstrap configuration.

## Network Model

The EC2 workload remains private.

No public IP address or inbound SSH access is required for operational management.

Systems Manager connectivity is provided through private VPC interface endpoints.

The CloudWatch Agent uses the workload's AWS identity to deliver logs to CloudWatch Logs.

## Terraform Components

The observability capability is implemented as a reusable Terraform module:

modules/
└── observability/
    └── cloudwatch-agent/
        ├── main.tf
        ├── variables.tf
        ├── locals.tf
        └── outputs.tf

The module provisions the CloudWatch Log Group and exposes its name and ARN to consuming stacks.

The compute stack configures the EC2 workload to install and run the Amazon CloudWatch Agent and collect nginx logs.

## Log Collection

The CloudWatch Agent collects:

nginx access logs
nginx error logs

Logs are written to:

/aws/ec2/nhs-dev/nginx

Each EC2 instance receives separate streams using the instance ID:

{instance_id}/access
{instance_id}/error

This provides workload-level separation while allowing logs to be queried centrally through CloudWatch Logs.

## IAM

The EC2 workload role includes:
* AmazonSSMManagedInstanceCore
* CloudWatchAgentServerPolicy

AmazonSSMManagedInstanceCore provides Systems Manager management capabilities.

CloudWatchAgentServerPolicy provides the permissions required by the CloudWatch Agent to publish collected telemetry to CloudWatch.

The workload continues to use a dedicated EC2 instance profile rather than reusing the Terraform execution identity.

## Validation

The implementation was validated after deployment using AWS Systems Manager and AWS CLI.

Validated controls include:
* Terraform plan reports no changes after deployment
* EC2 instance reports Online through Systems Manager
* Nginx service is active
* CloudWatch Agent is active
* CloudWatch Agent configuration is accepted
* Nginx error log stream appears in CloudWatch Logs
* Nginx access log stream appears after generating application requests
* CloudWatch Log Group is managed through Terraform
* HTTP requests generating nginx access-log events

The validation demonstrates the complete logging path:

          Nginx
            │
            ▼
        Local log files
            │
            ▼
        CloudWatch Agent
            │
            ▼
        CloudWatch Logs

## Design Considerations

This implementation intentionally establishes centralized logging before introducing more advanced observability capabilities.

Future extensions may include:
* EC2 and application metrics
* CloudWatch alarms
* Operational dashboards
* Log metric filters
* Alerting integrations
* Additional workload log sources

These capabilities are outside the scope of the current observability foundation.

## Security scanning notes
Checkov identifies several controls that are intentionally deferred in the development/reference environment, including ALB access logging, HTTPS termination, WAF protection, deletion protection, customer-managed KMS encryption for CloudWatch Logs, extended log retention, and S3 cross-region replication.

These controls are considered production hardening items rather than blockers for the current infrastructure milestone. Some findings are also policy/context mismatches, such as security-group attachment and NAT EIP checks.

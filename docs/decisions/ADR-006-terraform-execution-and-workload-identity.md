## ADR-006: Terraform Execution Role and Workload Identity
Status: Accepted
Date: 2026-08-06
Decision Owners: Infrastructure Engineering
Scope: AWS IAM and Terraform execution

Context
The AWS environment requires Terraform to provision and manage infrastructure resources, including IAM roles, networking resources, security controls, and compute-related resources.

Granting broad administrative permissions directly to the human IAM user would create unnecessary privilege and make the human identity responsible for infrastructure-level permissions.

The platform therefore separates:
1. The human IAM identity used to initiate infrastructure changes.
2. The Terraform execution role used to perform infrastructure operations.
3. IAM roles assigned to AWS workloads.

The development IAM user wterra-dev is permitted to assume the dedicated Terraform execution role nhs-dev-terraform-role.

The Terraform execution role has AdministratorAccess in the current development environment because the platform is still in its infrastructure-foundation stage and Terraform must be capable of provisioning resources across multiple AWS services.

Decision
Terraform infrastructure changes will be executed through the dedicated IAM role: nhs-dev-terraform-role

The human IAM user will not receive direct administrative permissions.

The trust relationship on the Terraform execution role permits wterra-dev to assume the role using AWS Security Token Service (STS).

The resulting access model is:

Human IAM User
wterra-dev
      |
      | sts:AssumeRole
      v
Terraform Execution Role
nhs-dev-terraform-role
      |
      | infrastructure permissions
      v
AWS Resources

Terraform is therefore expected to operate using the assumed-role session rather than the base IAM user credentials.

Workload Identity
Workloads will use dedicated IAM roles rather than inheriting the permissions of the Terraform execution identity.

For EC2 workloads, the platform provisions:
1. nhs-dev-ec2-role
2. nhs-dev-ec2-profile

The EC2 role is trusted by the EC2 service and is associated with an instance profile.

The role currently receives the AWS-managed policy: AmazonSSMManagedInstanceCore

This provides the permissions required for AWS Systems Manager management of EC2 instances.

The resulting separation is:

wterra-dev
   |
   +--> AssumeRole
          |
          v
nhs-dev-terraform-role
          |
          +--> Creates/manages infrastructure
          |
          +--> Creates workload IAM roles
                         |
                         v
                  nhs-dev-ec2-role
                         |
                         +--> EC2 workload

Rationale
This design establishes a clear separation between:

Human identity
The human identity is primarily responsible for authentication and initiating infrastructure operations.

Infrastructure identity
The Terraform execution role represents the identity of the infrastructure automation process.

Workload identity
The EC2 IAM role represents the identity of the application workload.

This prevents the EC2 workload from inheriting infrastructure-management permissions and prevents the human IAM identity from requiring broad infrastructure permissions directly.

Security Considerations
The current AdministratorAccess permission on the Terraform execution role is intentionally broad and is appropriate only for the current development-stage platform foundation.

As the platform matures, permissions should be reviewed and progressively reduced toward least privilege where practical.

The trust relationship should remain limited to explicitly authorized identities.

Terraform credentials should use temporary STS sessions rather than long-lived administrative credentials wherever possible.

Consequences
Positive
- Human and infrastructure permissions are separated.
- Terraform has a clearly identifiable AWS execution identity.
- Workloads receive dedicated identities.
- EC2 does not require static AWS access keys.
- The architecture provides a path toward least-privilege IAM as the platform matures.

Trade-offs
- Terraform execution requires successful role assumption.
- Troubleshooting requires understanding both the source identity and assumed role.
- AdministratorAccess remains broader than the eventual production target and must be reduced as the platform evolves.

Future Considerations
The Terraform execution role should eventually be evaluated for a more restrictive permission model.

Production environments should use stronger controls around:
- role assumption
- MFA and/or federated identity
- permission boundaries
- session duration
- deployment authorization
- CI/CD workload identity
- least-privilege policies

The EC2 workload role should also be reviewed as additional application requirements are introduced.

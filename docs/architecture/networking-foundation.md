1. Architecture overview
The networking foundation establishes a secure AWS VPC architecture using a three-tier subnet design across multiple Availability Zones (starting with two AZs).

The design separates internet-facing resources, application workloads, and data services into isolated network layers.

2. Architecture diagram

                    Internet
                       |
                 Internet Gateway
                       |
        +--------------+--------------+
        |                             |
 Public Subnet AZ-A             Public Subnet AZ-B
        |                             |
        +-------------+---------------+
                      |
                 NAT Gateway
                      |
        +-------------+---------------+
        |                             |
 Private App AZ-A              Private App AZ-B
        |                             |
        +-------------+---------------+
                      |
              Private Data Tier
        |                             |
 Private Data AZ-A             Private Data AZ-B


3. Design decisions
- Decision: Reason
  - Multi-AZ subnets: To improve availability
  - Private application tier: Reduce exposure to external threats
  - Separate data tier: Security segmentation unbundling application and data. Also enables modular maintenance
  - NAT Gateway: Allow outbound traffic, e.g., updates, without inbound exposure
  - Terraform modules: Reusable infrastructure components


4. Operational notes
- Region: ca-central-1

- IaC tool: Terraform

- Validation:
  - terraform validate
  - tflint
  - checkov
  - GitHub Actions

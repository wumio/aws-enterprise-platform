# ADR-011: Availability-Zone-Local NAT Gateways

## Status

Accepted

## Context

The networking foundation initially used a single NAT Gateway to provide internet egress for private application and data subnets across two Availability Zones.

While this design reduced infrastructure cost, it introduced a cross-AZ dependency for private subnet egress. Private workloads in one Availability Zone could depend on a NAT Gateway located in another Availability Zone.

For a production-inspired infrastructure platform, the network should minimize unnecessary cross-AZ dependencies and maintain independent egress paths where practical.

## Decision

Deploy one NAT Gateway per Availability Zone and associate each NAT Gateway with a public subnet in its corresponding Availability Zone.

Private application and data subnets will use Availability-Zone-specific private route tables. Each private route table will route internet-bound traffic through the NAT Gateway in the same Availability Zone.

The resulting architecture is:

```text
Availability Zone A
    |
    +-- Public subnet
    |      |
    |    NAT Gateway A
    |      |
    +-- Private route table A
           |
           +-- Private application subnet A
           |
           +-- Private data subnet A


Availability Zone B
    |
    +-- Public subnet
    |      |
    |    NAT Gateway B
    |      |
    +-- Private route table B
           |
           +-- Private application subnet B
           |
           +-- Private data subnet B

This creates AZ-local private subnet egress and removes the dependency on a single shared NAT Gateway.

## Rationale

The decision prioritizes availability-zone isolation and operational resilience over minimum infrastructure cost.

If a NAT Gateway or its associated Availability Zone becomes unavailable, private subnet egress in the other Availability Zone remains independent.

The design also provides a clear and predictable relationship between:
* Availability Zone
* Public subnet
* NAT Gateway
* Private route table
* Private application subnet
* Private data subnet
* Trade-offs

## Benefits

* Reduces cross-AZ dependency for private subnet internet egress
* Provides an independent NAT Gateway per Availability Zone
* Improves fault isolation
* Provides AZ-local routing for private workloads
* Establishes a production-oriented networking pattern

## Costs

* Increases NAT Gateway hourly costs
* Requires an additional Elastic IP per Availability Zone
* Requires separate private route tables
* Increases the number of networking resources that must be operated

For this production-inspired reference platform, the additional cost is accepted in exchange for improved resilience and clearer failure-domain boundaries.

## Implementation

The networking module creates NAT Gateways and Elastic IPs based on the configured Availability Zones.

Each private route table is created for a specific Availability Zone and routes 0.0.0.0/0 through the NAT Gateway in that same Availability Zone.

Private application and private data subnets are associated with the route table corresponding to their Availability Zone.

The current implementation supports two Availability Zones.

## Validation

The implementation was runtime-validated in AWS after deployment.

Validation confirmed:
* Two NAT Gateways exist in ca-central-1
* Both NAT Gateways are in available state
* Each NAT Gateway is deployed in a different Availability Zone
* Each private route table has an active default route to its local NAT Gateway
* Private application and data subnets are associated with their corresponding AZ-specific private route table
* No existing networking resources were destroyed during the migration

The Terraform apply completed with:
4 added
5 changed
0 destroyed

## Consequences

The networking foundation now has AZ-local private egress.

Future networking changes should preserve the relationship between private subnets and their corresponding NAT Gateway unless a deliberate architectural decision changes this design.

Future cost-optimization work may evaluate alternatives such as NAT Gateway cost controls, centralized egress architectures, or other AWS-native egress patterns. Such changes should be evaluated separately against their availability, security, operational, and cross-AZ cost implications.

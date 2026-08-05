# Standardized stack state paths

The networking and compute stacks followed the dev/<stack> convention, while the security stack used security/dev. This created an inconsistent state layout and caused the compute stack's terraform_remote_state lookup to fail initially.

Decision:
Standardize the environment stack with the state keys as:
<environment>/<stack>/terraform.tfstate

dev/networking/terraform.tfstate
dev/security/terraform.tfstate
dev/compute/terraform.tfstate

Consequences:
- Consistent state organization
- Predictable remote-state references
- Easier automation
- Easier onboarding
- Cleaner multi-environment expansion

Trade-off:
- The security stacks required state migration in order to adopt the convention. The security/dev was migrated without recreating infrastructure.

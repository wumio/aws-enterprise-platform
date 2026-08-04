# Remote State Management
Terraform state management was implemented using Amazon S3 remote state storage with encryption enabled through AWS KMS and native S3 locking.

The bootstrap layer was initially deployed locally to create the backend resources, after which state was migrated to the remote backend. This approach enables collaboration, improves state security, and establishes a scalable foundation for future infrastructure stacks.

# State naming convention/location:
Local: stacks/<stack>/<environment>/
Remote state: <environment>/<stack>/<state_file>, e.g., dev/networking/terraform.tfstate

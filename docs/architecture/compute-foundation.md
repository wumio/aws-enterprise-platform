# Compute foundation

The compute stack consumes data exposed by networking and security stacks.

It does not interact directly with the modules, but consumes data from the remote states of both stacks.

The plan:
Networking
    │
    │ remote state
    ▼
Security
    │
    │ remote state
    ▼
Compute
    │
    ├── IAM / SSM
    ├── EC2
    ├── ALB
    └── Auto Scaling

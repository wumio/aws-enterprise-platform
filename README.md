# AWS Enterprise Platform

Production-inspired AWS infrastructure platform built with Terraform.

## Objectives

- Secure remote Terraform state
- Enterprise networking
- Infrastructure as Code
- Cloud security
- Modular architecture
- CI/CD automation
- Observability
- Disaster recovery

## Current Status

- ✅ Bootstrap infrastructure
- ✅ Remote state management
- ✅ Backend hardening
- 🚧 CI/CD pipeline
- ⏳ Networking stack
- ⏳ Identity stack
- ⏳ Compute stack


## Local Development

Install pre-commit:

```bash
pip install pre-commit
pre-commit install
```

Run all local quality checks:

```bash
pre-commit run --all-files
```

The repository uses pre-commit to automatically:

- Format Terraform code
- Validate Terraform configuration
- Run TFLint
- Perform basic repository hygiene checks

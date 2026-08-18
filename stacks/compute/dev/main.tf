data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "nhs-bootstrap-s3-tfstate"
    key    = "dev/networking/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = "nhs-bootstrap-s3-tfstate"
    key    = "dev/security/terraform.tfstate"
    region = var.aws_region
  }
}

module "ec2_instance_role" {
  source = "../../../modules/iam/ec2-instance-role"

  name        = var.name
  environment = var.environment
}

module "private_ec2" {
  source = "../../../modules/compute/private-ec2"

  name                  = var.name
  environment           = var.environment
  ami                   = "ami-06a19372fab295de9"
  subnet_id             = data.terraform_remote_state.networking.outputs.private_app_subnet_ids[0]
  security_group_id     = data.terraform_remote_state.security.outputs.application_security_group_id
  instance_profile_name = module.ec2_instance_role.instance_profile_name

  user_data = <<-EOF
#!/bin/bash
set -euo pipefail

dnf install -y nginx

cat > /etc/nginx/nginx.conf <<'NGINX'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent"';

    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name _;

        location = /health {
            default_type text/plain;
            return 200 "OK\n";
        }

        location / {
            default_type text/plain;
            return 200 "Private EC2 workload is healthy\n";
        }
    }
}
NGINX

systemctl enable --now nginx

# Install the Amazon CloudWatch Agent
dnf install -y amazon-cloudwatch-agent

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWAGENT'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "${module.cloudwatch_agent.nginx_log_group_name}",
            "log_stream_name": "{instance_id}/access",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "${module.cloudwatch_agent.nginx_log_group_name}",
            "log_stream_name": "{instance_id}/error",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWAGENT

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
EOF
}

module "cloudwatch_agent" {
  source = "../../../modules/observability/cloudwatch-agent"

  name        = var.name
  environment = var.environment

  retention_in_days = 30
}

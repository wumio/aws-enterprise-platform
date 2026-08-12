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
  EOF
}

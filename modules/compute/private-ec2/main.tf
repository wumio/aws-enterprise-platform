resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = false
  user_data                   = var.user_data
  user_data_replace_on_change = true

  lifecycle {
    create_before_destroy = true
  }

  monitoring = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = var.root_volume_size

    tags = merge(
      local.common_tags,
      {
        Name = "${local.name_prefix}-root-volume"
      }
    )
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.instance_name
    }
  )
}

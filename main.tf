terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Upload your local public key from your project directory to AWS
resource "aws_key_pair" "deployer_key" {
  key_name   = "mern-ec2-deployer-key"
  public_key = file("${path.module}/id_rsa.pub")
}

# Security Group
resource "aws_security_group" "mern_sg" {
  name        = "mern-unified-sg"
  description = "Allow inbound traffic for SSH, Frontend, Admin, and Backend"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Single EC2 Instance
resource "aws_instance" "app_server" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.small"

  vpc_security_group_ids = [aws_security_group.mern_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              set -e
              export DEBIAN_FRONTEND=noninteractive

              # Update system and install prerequisite tools
              apt-get update -y
              apt-get install -y curl git ca-certificates gnupg docker-compose-plugin

              # Install Docker using official script
              curl -fsSL https://get.docker.com -o get-docker.sh
              sh get-docker.sh

              # Enable Docker service and grant permissions to ubuntu user
              systemctl enable --now docker
              usermod -aG docker ubuntu

              # Get server public IP via IMDSv2
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

              # Clone application repository and grant permissions to ubuntu user
              mkdir -p /home/ubuntu/app
              git clone https://github.com/Ranmmy001/Full_MERN_Stack_Ecommerce_Project_1.git /home/ubuntu/app
              chown -R ubuntu:ubuntu /home/ubuntu/app
              cd /home/ubuntu/app

              # Set environment variables for builds
              echo "REACT_APP_API_URL=http://$PUBLIC_IP:5000" > Frontend/.env
              echo "REACT_APP_API_URL=http://$PUBLIC_IP:5000" > Admin/.env
              echo "PORT=5000" > Backend/.env

              # Build and launch application containers
              docker compose up -d --build
              EOF
  tags = {
    Name = "MERN-Containerized-Server"
  }
}

output "server_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "Public IP address of the containerized server"
}
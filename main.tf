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

# 1. SSH Key Pair
resource "aws_key_pair" "deployer_key" {
  key_name   = "mern-ec2-deployer-key"
  public_key = file("${path.module}/id_rsa.pub")
}

# 2. Security Group
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

# 3. Single EC2 Instance
resource "aws_instance" "app_server" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.small"

  vpc_security_group_ids = [aws_security_group.mern_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              set -e
              export DEBIAN_FRONTEND=noninteractive

              # 1. Stop background updates & wait for locks to clear
              systemctl stop unattended-upgrades || true
              while systemctl is-active --quiet unattended-upgrades; do sleep 1; done
              while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 2; done
              while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 2; done

              # 2. Install Docker, Docker Compose Plugin, Git & Curl
              apt-get update -y
              apt-get install -y docker.io docker-compose-plugin git curl

              # 3. Enable Docker service and give ubuntu user permissions
              systemctl enable --now docker
              usermod -aG docker ubuntu

              # 4. Fetch Public IP dynamically using IMDSv2
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

              # 5. Clone repository and fix permissions
              rm -rf /home/ubuntu/app
              mkdir -p /home/ubuntu/app
              git clone https://github.com/Ranmmy001/Full_MERN_Stack_Ecommerce_Project_1.git /home/ubuntu/app
              chown -R ubuntu:ubuntu /home/ubuntu/app
              cd /home/ubuntu/app

              # 6. Inject dynamic environment variables
              echo "REACT_APP_API_URL=http://$PUBLIC_IP:5000" > Frontend/.env
              echo "REACT_APP_API_URL=http://$PUBLIC_IP:5000" > Admin/.env
              echo "PORT=5000" > Backend/.env

              # 7. Launch containers cleanly
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
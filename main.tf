terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"    
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security Group for SSH, Frontend, Admin, and Backend
resource "aws_security_group" "mern_sg" {
  name        = "mern-unified-sg"
  description = "Allow inbound traffic for SSH, Frontend, Admin, and Backend"

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  #https access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic for React Frontend (Storefront)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic for React Admin Dashboard
  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic for Express Backend API
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

# Single EC2 Instance hosting Docker Compose for all 3 services
resource "aws_instance" "app_server" {
  ami           = "ami-0b6d9d3d33ba97d99" 
  instance_type = "t3.small" # Upgraded to t3.small (2GB RAM) to prevent memory crashes during React builds

  vpc_security_group_ids = [aws_security_group.mern_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # 1. Update system and install Docker + Docker Compose + Git
              apt update -y
              apt install -y git docker.io docker-compose

              # 2. Enable and start Docker service
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu

              # 3. Clone application repository
              cd /home/ubuntu
              git clone ${var.github_repo_url} app
              cd app

              # 4. Generate root .env file for Docker Compose
              cat <<EOT > .env
              PORT=5000
              MONGO_URI="${var.mongodb_url}"
              JWT_SECRET="${var.jwt_secret}"
              EOT

              # 5. Fix permissions and spin up all 3 containers
              chown -R ubuntu:ubuntu /home/ubuntu/app
              docker-compose up -d --build
              EOF

  tags = {
    Name = "MERN-Containerized-Server"
  }
}

# Output the single Public IP for your entire stack
output "server_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "Public IP address of the containerized server"
}
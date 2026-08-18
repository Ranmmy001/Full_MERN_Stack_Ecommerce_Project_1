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

# 1. Create Security Group for Port 22 (SSH) & Port 5000 (Backend)
resource "aws_security_group" "backend_sg" {
  name        = "mern-backend-sg"
  description = "Allow inbound traffic for SSH and Backend API"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    # Allow inbound traffic for Backend API
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow inbound traffic for React Frontend
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Add this block for the Admin Dashboard
  ingress {
    from_port   = 3001
    to_port     = 3001
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

# 2. Deploy EC2 Instance
resource "aws_instance" "backend_server" {
  ami           = "ami-0b6d9d3d33ba97d99" 
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  # Boot script runs software installation and passes secrets into .env
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Update and install Node.js + PM2
              apt update -y && apt install -y git curl
              curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
              apt install -y nodejs
              npm install -g pm2

              # Clone Repo
              cd /home/ubuntu
              git clone ${var.github_repo_url} app
              cd app/Backend

              # Install dependencies
              npm install

              # Generate .env file dynamically
              cat <<EOT > .env
              PORT=5000
              MONGODB_URL="${var.mongodb_url}"
              JWT_SECRET="${var.jwt_secret}"
              EOT

              # Set correct ownership & start application via PM2
              chown -R ubuntu:ubuntu /home/ubuntu/app
              sudo -u ubuntu pm2 start index.js --name "mern-backend"
              sudo -u ubuntu pm2 save
              EOF

  tags = {
    Name = "MERN-Backend-Server"
  }
}


# Deploy Frontend EC2 Instance
resource "aws_instance" "frontend_server" {
  ami           = "ami-0b6d9d3d33ba97d99" 
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # 1. Update system and install Node.js + PM2 + serve
              apt update -y && apt install -y git curl
              curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
              apt install -y nodejs
              npm install -g pm2 serve

              # 2. Clone repo into home directory
              cd /home/ubuntu
              git clone ${var.github_repo_url} app
              cd app/Frontend

              # 3. Install dependencies and build production static files
              npm install
              npm run build

              # 4. Set correct ownership and serve on Port 3000 using PM2
              chown -R ubuntu:ubuntu /home/ubuntu/app
              sudo -u ubuntu pm2 serve build 3000 --name "mern-frontend" --spa
              sudo -u ubuntu pm2 save
              EOF

  tags = {
    Name = "MERN-Frontend-Server"
  }
}

# Output the public IP for the frontend
output "frontend_public_ip" {
  value       = aws_instance.frontend_server.public_ip
  description = "Public IP address of the deployed frontend server"
}


output "ec2_public_ip" {
  value       = aws_instance.backend_server.public_ip
  description = "Public IP address of the deployed backend server"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "mongodb_url" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "github_repo_url" {
  type        = string
  description = "GitHub repository URL to clone"
  default     = "https://github.com/Ranmmy001/Full_MERN_Stack_Ecommerce_Project_1.git"
}
variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "inter-region-egress"
}

variable "singapore_vpc_cidr" {
  description = "CIDR block for Singapore VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "tokyo_vpc_cidr" {
  description = "CIDR block for Tokyo VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "tokyo_public_subnet_cidr" {
  description = "CIDR block for Tokyo public subnet"
  type        = string
  default     = "10.2.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
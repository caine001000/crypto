# ============================================
# Singapore VPC
# ============================================

resource "aws_vpc" "singapore" {
  provider             = aws.singapore
  cidr_block           = var.singapore_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  depends_on = [aws_instance.tokyo_proxy]

  tags = {
    Name    = "${var.project_name}-singapore-vpc"
    Project = var.project_name
  }
}

resource "aws_security_group" "singapore_ec2" {
  provider    = aws.singapore
  name        = "${var.project_name}-singapore-ec2-sg"
  description = "Security group for Singapore EC2 instance"
  vpc_id      = aws_vpc.singapore.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-singapore-ec2-sg"
    Project = var.project_name
  }
}

data "aws_ami" "ubuntu_singapore" {
  provider    = aws.singapore
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "singapore" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "singapore" {
  provider   = aws.singapore
  key_name   = "${var.project_name}-singapore-key"
  public_key = tls_private_key.singapore.public_key_openssh

  tags = {
    Name    = "${var.project_name}-singapore-key"
    Project = var.project_name
  }
}

resource "local_file" "singapore_private_key" {
  content         = tls_private_key.singapore.private_key_pem
  filename        = "${path.module}/singapore-key.pem"
  file_permission = "0400"
}

# ============================================
# Singapore EC2 with Proxy Config
# ============================================

resource "aws_instance" "singapore" {
  provider                    = aws.singapore
  ami                         = data.aws_ami.ubuntu_singapore.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.singapore_public.id
  vpc_security_group_ids      = [aws_security_group.singapore_ec2.id]
  key_name                    = aws_key_pair.singapore.key_name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/user_data/user_data_singapore.sh", {
    tokyo_proxy_ip = aws_instance.tokyo_proxy.private_ip
  })

  depends_on = [
    aws_instance.tokyo_proxy,
    aws_vpc_peering_connection_accepter.tokyo
  ]

  tags = {
    Name    = "${var.project_name}-singapore-ec2"
    Project = var.project_name
  }
}
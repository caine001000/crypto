# ============================================
# Tokyo VPC with Public Subnet
# ============================================

resource "aws_vpc" "tokyo" {
  provider             = aws.tokyo
  cidr_block           = var.tokyo_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-tokyo-vpc"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "tokyo" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.tokyo.id

  tags = {
    Name    = "${var.project_name}-tokyo-igw"
    Project = var.project_name
  }
}

resource "aws_subnet" "tokyo_public" {
  provider                = aws.tokyo
  vpc_id                  = aws_vpc.tokyo.id
  cidr_block              = var.tokyo_public_subnet_cidr
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-tokyo-public-subnet"
    Project = var.project_name
  }
}

resource "aws_route_table" "tokyo_public" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.tokyo.id

  tags = {
    Name    = "${var.project_name}-tokyo-public-rt"
    Project = var.project_name
  }
}

resource "aws_route" "tokyo_internet" {
  provider               = aws.tokyo
  route_table_id         = aws_route_table.tokyo_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tokyo.id
}

resource "aws_route_table_association" "tokyo_public" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.tokyo_public.id
  route_table_id = aws_route_table.tokyo_public.id
}

# ============================================
# Tokyo Proxy EC2 with Squid
# ============================================

resource "aws_security_group" "tokyo_proxy" {
  provider    = aws.tokyo
  name        = "${var.project_name}-tokyo-proxy-sg"
  description = "Security group for Tokyo proxy"
  vpc_id      = aws_vpc.tokyo.id

  ingress {
    description = "HTTP proxy from Singapore"
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = [var.singapore_vpc_cidr]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-tokyo-proxy-sg"
    Project = var.project_name
  }
}

data "aws_ami" "ubuntu_tokyo" {
  provider    = aws.tokyo
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

resource "tls_private_key" "tokyo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tokyo" {
  provider   = aws.tokyo
  key_name   = "${var.project_name}-tokyo-key"
  public_key = tls_private_key.tokyo.public_key_openssh

  tags = {
    Name    = "${var.project_name}-tokyo-key"
    Project = var.project_name
  }
}

resource "local_file" "tokyo_private_key" {
  content         = tls_private_key.tokyo.private_key_pem
  filename        = "${path.module}/tokyo-key.pem"
  file_permission = "0400"
}

resource "aws_instance" "tokyo_proxy" {
  provider                    = aws.tokyo
  ami                         = data.aws_ami.ubuntu_tokyo.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.tokyo_public.id
  vpc_security_group_ids      = [aws_security_group.tokyo_proxy.id]
  key_name                    = aws_key_pair.tokyo.key_name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = file("${path.module}/user_data/user_data_tokyo.sh")

  tags = {
    Name    = "${var.project_name}-tokyo-proxy"
    Project = var.project_name
  }
}
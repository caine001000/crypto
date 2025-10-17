# ============================================
# Public Subnet and IGW for Singapore EC2
# ============================================

resource "aws_subnet" "singapore_public" {
  provider                = aws.singapore
  vpc_id                  = aws_vpc.singapore.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-singapore-public-subnet"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "singapore" {
  provider = aws.singapore
  vpc_id   = aws_vpc.singapore.id

  tags = {
    Name    = "${var.project_name}-singapore-igw"
    Project = var.project_name
  }
}

resource "aws_route_table" "singapore_public" {
  provider = aws.singapore
  vpc_id   = aws_vpc.singapore.id

  tags = {
    Name    = "${var.project_name}-singapore-public-rt"
    Project = var.project_name
  }
}

# Route to internet for SSH access only
resource "aws_route" "singapore_public_internet" {
  provider               = aws.singapore
  route_table_id         = aws_route_table.singapore_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.singapore.id
}

# Route to Tokyo VPC via peering
resource "aws_route" "singapore_public_to_tokyo" {
  provider                  = aws.singapore
  route_table_id            = aws_route_table.singapore_public.id
  destination_cidr_block    = var.tokyo_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.singapore_tokyo.id
  
  depends_on = [aws_vpc_peering_connection_accepter.tokyo]
}

resource "aws_route_table_association" "singapore_public" {
  provider       = aws.singapore
  subnet_id      = aws_subnet.singapore_public.id
  route_table_id = aws_route_table.singapore_public.id
}
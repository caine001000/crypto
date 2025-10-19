
resource "aws_vpc" "tokyo" {
  provider             = aws.tokyo
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tokyo-vpc"
  }
}

resource "aws_subnet" "tokyo_public" {
  provider                = aws.tokyo
  vpc_id                  = aws_vpc.tokyo.id
  cidr_block              = "10.2.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tokyo-public-subnet"
  }
}

resource "aws_internet_gateway" "tokyo" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.tokyo.id

  tags = {
    Name = "tokyo-igw"
  }
}

resource "aws_route_table" "tokyo_public" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.tokyo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tokyo.id
  }

  tags = {
    Name = "tokyo-public-rt"
  }
}

resource "aws_route" "tokyo_to_singapore" {
  provider                  = aws.tokyo
  route_table_id            = aws_route_table.tokyo_public.id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.singapore_tokyo.id
}

resource "aws_route_table_association" "tokyo_public" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.tokyo_public.id
  route_table_id = aws_route_table.tokyo_public.id
}

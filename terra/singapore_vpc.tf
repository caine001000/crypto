
resource "aws_vpc" "singapore" {
  provider             = aws.singapore
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "singapore-vpc"
  }
}

resource "aws_subnet" "singapore_public" {
  provider                = aws.singapore
  vpc_id                  = aws_vpc.singapore.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "singapore-public-subnet"
  }
}

resource "aws_subnet" "singapore_private" {
  provider          = aws.singapore
  vpc_id            = aws_vpc.singapore.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "singapore-private-subnet"
  }
}

resource "aws_internet_gateway" "singapore" {
  provider = aws.singapore
  vpc_id   = aws_vpc.singapore.id

  tags = {
    Name = "singapore-igw"
  }
}

resource "aws_route_table" "singapore_public" {
  provider = aws.singapore
  vpc_id   = aws_vpc.singapore.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.singapore.id
  }

  tags = {
    Name = "singapore-public-rt"
  }
}

resource "aws_route_table_association" "singapore_public" {
  provider       = aws.singapore
  subnet_id      = aws_subnet.singapore_public.id
  route_table_id = aws_route_table.singapore_public.id
}

resource "aws_route_table" "singapore_private" {
  provider = aws.singapore
  vpc_id   = aws_vpc.singapore.id

  tags = {
    Name = "singapore-private-rt"
  }
}


resource "aws_route" "singapore_to_tokyo" {
  provider                  = aws.singapore
  route_table_id            = aws_route_table.singapore_private.id
  destination_cidr_block    = aws_vpc.tokyo.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.singapore_tokyo.id
}

resource "aws_route_table_association" "singapore_private" {
  provider       = aws.singapore
  subnet_id      = aws_subnet.singapore_private.id
  route_table_id = aws_route_table.singapore_private.id
}

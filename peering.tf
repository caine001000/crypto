# ============================================
# VPC Peering Connection
# ============================================

resource "aws_vpc_peering_connection" "singapore_tokyo" {
  provider    = aws.singapore
  vpc_id      = aws_vpc.singapore.id
  peer_vpc_id = aws_vpc.tokyo.id
  peer_region = "ap-northeast-1"
  auto_accept = false

  depends_on = [
    aws_vpc.singapore,
    aws_vpc.tokyo
  ]

  tags = {
    Name    = "${var.project_name}-singapore-to-tokyo"
    Project = var.project_name
    Side    = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "tokyo" {
  provider                  = aws.tokyo
  vpc_peering_connection_id = aws_vpc_peering_connection.singapore_tokyo.id
  auto_accept               = true

  tags = {
    Name    = "${var.project_name}-singapore-to-tokyo"
    Project = var.project_name
    Side    = "Accepter"
  }
}

# Route from Tokyo back to Singapore VPC
resource "aws_route" "tokyo_to_singapore" {
  provider                  = aws.tokyo
  route_table_id            = aws_route_table.tokyo_public.id
  destination_cidr_block    = var.singapore_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.singapore_tokyo.id

  depends_on = [aws_vpc_peering_connection_accepter.tokyo]
}
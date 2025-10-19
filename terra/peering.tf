
resource "aws_vpc_peering_connection" "singapore_tokyo" {
  provider    = aws.singapore
  vpc_id      = aws_vpc.singapore.id
  peer_vpc_id = aws_vpc.tokyo.id
  peer_region = "ap-northeast-1"
  auto_accept = false

  tags = {
    Name = "singapore-to-tokyo-peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "tokyo" {
  provider                  = aws.tokyo
  vpc_peering_connection_id = aws_vpc_peering_connection.singapore_tokyo.id
  auto_accept               = true

  tags = {
    Name = "tokyo-peering-accepter"
  }
}

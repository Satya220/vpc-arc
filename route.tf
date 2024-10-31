resource "aws_route_table" "bast_route" {
  vpc_id = aws_vpc.bast.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bast_gw.id
  }

  tags = {
    Name = "route_bast"
  }
}

resource "aws_route_table" "app_route" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_gw.id
  }

  tags = {
    Name = "route_app"
  }
}

resource "aws_route_table" "nat_route" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "nat_route"
  }
}

resource "aws_route_table" "trans_route" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = aws_vpc.bast.cidr_block
    gateway_id = aws_ec2_transit_gateway.ec2_transit.id
  }

  tags = {
    Name = "trans_route"
  }
}

resource "aws_route_table" "btrt_route" {
  vpc_id = aws_vpc.bast.id

  route {
    cidr_block = aws_vpc.app.cidr_block
    gateway_id = aws_ec2_transit_gateway.ec2_transit.id
  }

  tags = {
    Name = "btrt_route"
  }
}

# resource "aws_route_table" "nigw_route" {
#   vpc_id = aws_vpc.app.id

#   route {
#     cidr_block = "18.202.128.71/32"
#     gateway_id = aws_internet_gateway.app_gw.id
#   }

#   tags = {
#     Name = "nigw_route"
#   }
# }

resource "aws_route_table_association" "bast_route_asso" {
  subnet_id      = aws_subnet.bastion.id
  route_table_id = aws_route_table.bast_route.id
}

resource "aws_route_table_association" "app_route_asso" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.app_route.id
}

resource "aws_route_table_association" "app_route_2_asso" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.app_route.id
}

resource "aws_route_table_association" "app_private_route_asso" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.nat_route.id
}

resource "aws_route_table_association" "app_private_route_2_asso" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.nat_route.id
}


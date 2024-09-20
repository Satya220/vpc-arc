resource "aws_vpc" "bast" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "bastion-vpc"
  }
}

resource "aws_vpc" "app" {
  cidr_block       = "172.32.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "app-vpc"
  }
}

resource "aws_subnet" "bastion" {
  vpc_id     = aws_vpc.bast.id
  cidr_block = "172.32.5.0/16"

  tags = {
    Name = "bastion"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.1.0/16"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.2.0/16"

  tags = {
    Name = "private"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.3.0/16"

  tags = {
    Name = "public_2"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.4.0/16"

  tags = {
    Name = "private_2"
  }
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.example]
}

resource "aws_internet_gateway" "bast_gw" {
  vpc_id = aws_vpc.bast.id

  tags = {
    Name = "bastion_gw"
  }
}

resource "aws_internet_gateway" "app_gw" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "app_gw"
  }
}

resource "aws_flow_log" "example" {
  iam_role_arn    = aws_iam_role.test_role.arn
  log_destination = aws_cloudwatch_log_group.example.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.app.id
}

resource "aws_cloudwatch_log_group" "example" {
  name = "example"
}

resource "aws_iam_role" "test_role" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.test_role.name
  policy_arn = arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs
}

resource "aws_ec2_transit_gateway" "ec2_transit" {
  description = "Transit gateway"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "bast_tgw" {
  subnet_ids         = [aws_subnet.bastion.id]
  transit_gateway_id = aws_ec2_transit_gateway.ec2_transit.id
  vpc_id             = aws_vpc.bastion.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app_tgw" {
  subnet_ids         = [aws_subnet.public.id,aws_subnet.public_2.id]
  transit_gateway_id = aws_ec2_transit_gateway.ec2_transit.id
  vpc_id             = aws_vpc.app.id
}

resource "aws_ec2_transit_gateway_connect" "bast_attachment" {
  transport_attachment_id = aws_ec2_transit_gateway_vpc_attachment.bast_tgw.id
  transit_gateway_id      = aws_ec2_transit_gateway.example.id
}

resource "aws_ec2_transit_gateway_connect" "app_attachment" {
  transport_attachment_id = aws_ec2_transit_gateway_vpc_attachment.app_tgw.id
  transit_gateway_id      = aws_ec2_transit_gateway.example.id
}

resource "aws_ec2_transit_gateway_route_table" "tgw_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.ec2_transit.id
}

resource "aws_ec2_transit_gateway_route" "example" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.bast_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw_rt.association_default_route_table_id
}

resource "aws_ec2_transit_gateway_route" "example" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw_rt.association_default_route_table_id
}
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
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "bastion"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.2.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "private"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.3.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "public_2"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.4.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "private_2"
  }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.example.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.bastion.id
  iam_instance_profile = aws_iam_instance_profile.test_profile.name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name   = "myKey"

  tags = {
    Name = "Bastion_Host"
  }
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.ec2_role.name
}

# resource "aws_instance" "app_1" {
#   ami           = aws_ami.copy.example.id
#   instance_type = "t3.micro"
#   subnet_id = aws_subnet.private.id
#   iam_instance_profile = aws_iam_role.test_role.name
#   security_groups = [aws_security_group.allow_ssh.id]

#   tags = {
#     Name = "App_1"
#   }
# }

# resource "aws_instance" "app_2" {
#   ami           = aws_ami.copy.example.id
#   instance_type = "t3.micro"
#   subnet_id = aws_subnet.private_2.id
#   iam_instance_profile = aws_iam_role.test_role.name
#   security_groups = [aws_security_group.allow_ssh.id]

#   tags = {
#     Name = "App_2"
#   }
# }

# resource "aws_ssm_activation" "foo" {
#   name               = "test_ssm_activation"
#   description        = "Test"
#   iam_role           = "arn:aws:iam::134955369621:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM"
#   registration_limit = "5"
#   # depends_on         = [aws_iam_role_policy_attachment.test_attach]
# }

resource "aws_launch_template" "boobar" {
  name          = "web_config"
  image_id      = "ami-0d64bb532e0502c46"
  instance_type = "t3.micro"
  key_name   = "myKey"
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  user_data = filebase64("${path.module}/webserver.sh")
  iam_instance_profile {
  name = aws_iam_instance_profile.test_profile.name
  }

}

resource "aws_autoscaling_group" "bar" {
  vpc_zone_identifier = [aws_subnet.private.id,aws_subnet.private_2.id]
  desired_capacity   = 2
  max_size           = 3
  min_size           = 1


launch_template {
    id      = aws_launch_template.boobar.id
    version = "$Latest"
  }
}



 resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "myKey"       # Create "myKey" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./myKey.pem"
  }
}

resource "aws_eip" "bast" {
  instance = aws_instance.bastion.id
  domain   = "vpc"
}

resource "aws_eip" "nat" {
  vpc      = true
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.bast.id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "private_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_pri" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4         = aws_vpc.bast.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22  
}

resource "aws_vpc_security_group_ingress_rule" "https_pri" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443  
}

resource "aws_vpc_security_group_ingress_rule" "http_pri" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_pri" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.app_gw]
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

resource "aws_flow_log" "app_log" {
  iam_role_arn    = aws_iam_role.test_role.arn
  log_destination = aws_cloudwatch_log_group.app_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.app.id
}

resource "aws_flow_log" "bast_log" {
  iam_role_arn    = aws_iam_role.test_role.arn
  log_destination = aws_cloudwatch_log_group.bast_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.bast.id
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name = "app_logs"
}

resource "aws_cloudwatch_log_group" "bast_logs" {
  name = "bast_logs"
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
          Service = "vpc-flow-logs.amazonaws.com"
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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_ec2_transit_gateway" "ec2_transit" {
  description = "Transit gateway"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "bast_tgw" {
  subnet_ids         = [aws_subnet.bastion.id]
  transit_gateway_id = aws_ec2_transit_gateway.ec2_transit.id
  vpc_id             = aws_vpc.bast.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app_tgw" {
  subnet_ids         = [aws_subnet.private.id,aws_subnet.private_2.id]
  transit_gateway_id = aws_ec2_transit_gateway.ec2_transit.id
  vpc_id             = aws_vpc.app.id
}

resource "aws_ec2_transit_gateway_connect" "bast_attachment" {
  transport_attachment_id = aws_ec2_transit_gateway_vpc_attachment.bast_tgw.id
  transit_gateway_id      = aws_ec2_transit_gateway.ec2_transit.id
}

resource "aws_ec2_transit_gateway_connect" "app_attachment" {
  transport_attachment_id = aws_ec2_transit_gateway_vpc_attachment.app_tgw.id
  transit_gateway_id      = aws_ec2_transit_gateway.ec2_transit.id
}

resource "aws_ec2_transit_gateway_route_table" "tgw_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.ec2_transit.id
}

resource "aws_ec2_transit_gateway_route" "bast-route" {
  destination_cidr_block         = aws_vpc.app.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
}

# resource "aws_ec2_transit_gateway_route" "bast-2-route" {
#   destination_cidr_block         = aws_vpc.private_2.cidr_block
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app_tgw.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
# }

resource "aws_ec2_transit_gateway_route" "app-route" {
  destination_cidr_block         = aws_vpc.bast.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.bast_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "bast_prop" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.bast_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "app_prop" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
}
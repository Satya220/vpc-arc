resource "aws_iam_role" "ec2_role" {
  name = "ssm_role"

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
    tag-key = "ec2_role"
  }
}

resource "aws_iam_role_policy_attachment" "ec2-attach" {
  role       = aws_iam_role.test_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.private.id,aws_subnet.private_2.id]
}

resource "aws_security_group" "lb_sg" {
  name        = "allow_traffic_alb"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.app.id


ingress {
  from_port = "80"
  to_port = "80"
  protocol = "tcp"
  cidr_blocks = ["182.48.217.35/32"]
}

egress {
  from_port = "0"
  to_port = "0"
  cidr_blocks = ["0.0.0.0/0"]
  protocol = "-1"
}


  tags = {
    Name = "allow_tls"
  }
}



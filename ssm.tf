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
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_lb" "main" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public.id,aws_subnet.public_2.id]
}

resource "aws_security_group" "lb_sg" {
  name        = "allow_traffic_alb"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.app.id


ingress {
  from_port = "80"
  to_port = "80"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

ingress {
  from_port = "443"
  to_port = "443"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
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

# resource "aws_lb_target_group" "test" {
#   name     = "alb-target-group"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.bast.id
# }

# resource "aws_lb_target_group_attachment" "tg_attach" {
#   target_group_arn = aws_lb_target_group.test.arn
#   target_id        = aws_instance.bastion.id
#   port             = 80
# }

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app.id
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.bar.name
  lb_target_group_arn    = aws_lb_target_group.test.arn
}

#Route 53
resource "aws_route53_zone" "primary" {
  name = "satya.aws.crlabs.cloud"
}

resource "aws_route53_record" "A-record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "satya.aws.crlabs.cloud"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "example" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "satya.aws.crlabs.cloud"
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
}
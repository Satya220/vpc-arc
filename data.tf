resource "aws_ami_copy" "example" {
  name              = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-20240801"
  description       = "A copy of ami-02fd062ee104754fc"
  source_ami_id     = "ami-02fd062ee104754fc"
  source_ami_region = "eu-west-1"

  tags = {
    Name = "HelloWorld"
  }
}
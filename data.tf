data "aws_ami" "example" {
  most_recent      = true
  owners           = ["979382823631"]

  filter {
    name   = "name"
    values = ["bitnami-processmaker-4.7.1-14-r21-linux-debian-11-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ami-0c61a52c1ebb85606
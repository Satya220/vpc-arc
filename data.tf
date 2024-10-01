resource "aws_ami_copy" "example" {
  name              = "bitnami-processmaker-4.7.1-14-r21-linux-debian-11-x86_64-hvm-ebs-nami"
  description       = "A copy of ami-0c61a52c1ebb85606"
  source_ami_id     = "ami-0c61a52c1ebb85606"
  source_ami_region = "eu-west-1"

  tags = {
    Name = "HelloWorld"
  }
}
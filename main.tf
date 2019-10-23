provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "example" {
  # https://cloud-images.ubuntu.com/locator/ec2/
  ami = "ami-017e1dd35b94fb074"
  instance_type = "t2.micro"
}

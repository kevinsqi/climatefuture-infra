provider "aws" {
  region = "us-west-2"
}

variable "server_port" {
  description = "The port the server will use for http reqs"
  type = number
  default = 8080
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "Public IP of web server"
}
output "public_dns" {
  value = aws_instance.example.public_dns
  description = "Public DNS of web server"
}


resource "aws_instance" "example" {
  # https://cloud-images.ubuntu.com/locator/ec2/
  ami = "ami-017e1dd35b94fb074"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags = {
    Name = "terraform-example"
  }
}

# Needed to allow EC2 instance to receive traffic on a port
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

provider "aws" {
  region = "us-west-2"
}

variable "server_port" {
  description = "The port the server will use for http reqs"
  type = number
  default = 8080
}

output "clb_dns_name" {
  value = aws_elb.example.dns_name
  description = "domain name of load balancer"
}

# Data source for querying for availability zones
data "aws_availability_zones" "all" {}

# Autoscaling group launch config
resource "aws_launch_configuration" "example" {
  # https://cloud-images.ubuntu.com/locator/ec2/
  image_id = "ami-017e1dd35b94fb074"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = data.aws_availability_zones.all.names

  min_size = 2
  max_size = 10

  # Register each instance into the CLB
  load_balancers = [aws_elb.example.name]
  # Use the CLB's health check to determine instance health
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# Use a CLB load balancer (ALB is better, but CLB simpler)
# to be in front of autoscaling group
resource "aws_elb" "example" {
  name = "terraform-asg-example"
  security_groups = [aws_security_group.elb.id]
  availability_zones = data.aws_availability_zones.all.names

  # If an instance is unhealthy, automatically stop 
  # routing traffic to it
  health_check {
    target = "HTTP:${var.server_port}/"
    interval = 30
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = var.server_port
    instance_protocol = "http"
  }
}

# Security group
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  # Allow all outbound
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

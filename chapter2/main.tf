provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "all" {}

resource "aws_security_group" "web_server_security_group" {
  name = "tf-up-and-running-web-server"

  ingress {
    from_port = "${var.web_server_port}"
    to_port = "${var.web_server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  name = "tf-up-and-running-load-balancer"

  ingress {
    from_port = "${var.lb_server_port}"
    to_port = "${var.lb_server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "web_server_launch_config" {
  image_id = "ami-40d28157"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.web_server_security_group.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World!" > index.html
              nohup busybox httpd -f -p "${var.web_server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_server_auto_scaling_group" {
  launch_configuration = "${aws_launch_configuration.web_server_launch_config.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  min_size = 2
  max_size = 10

  load_balancers = ["${aws_elb.web_server_load_balancer.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "tf-up-and-running"
    propagate_at_launch = true
  }
}

resource "aws_elb" "web_server_load_balancer" {
  name = "tf-up-and-running"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]

  "listener" {
    lb_port = "${var.lb_server_port}"
    lb_protocol = "http"
    instance_port = "${var.web_server_port}"
    instance_protocol = "http"
  }

  "health_check" {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.web_server_port}/"
  }
}

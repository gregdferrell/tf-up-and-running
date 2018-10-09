// Setup Remote State using S3 bucket created by bootstrap proj
terraform {
  backend "s3" {
    bucket = "gregdferrell-tf-up-and-running-state-ch3"
    key = "state/stage/services/web-server-cluster/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "tf-up-and-running-app-state-ch3"
  }
}

// Provider
provider "aws" {
  region = "${var.aws_region}"
}

// Data Sources
data "aws_availability_zones" "all" {}

data "terraform_remote_state" "mysqldb" {
  backend = "s3"

  config {
    bucket = "${var.state_bucket}"
    key = "state/stage/data-stores/mysql/terraform.tfstate"
    region = "${var.aws_region}"
  }
}

data "template_file" "user_data" {
  template = "${file("user-data.sh")}"

  vars {
    web_server_port = "${var.web_server_port}"
    db_address = "${data.terraform_remote_state.mysqldb.db_address}"
    db_port = "${data.terraform_remote_state.mysqldb.db_port}"
  }
}

// Resources
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

  user_data = "${data.template_file.user_data.rendered}"

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

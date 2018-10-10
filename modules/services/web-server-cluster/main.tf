// Data Sources
data "aws_availability_zones" "all" {}

data "terraform_remote_state" "mysqldb" {
  backend = "s3"

  config {
    bucket = "${var.db_remote_state_bucket}"
    key = "${var.db_remote_state_key}"
    region = "${var.aws_region}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    web_server_port = "${var.web_server_port}"
    db_address = "${data.terraform_remote_state.mysqldb.db_address}"
    db_port = "${data.terraform_remote_state.mysqldb.db_port}"
  }
}

// Resources
resource "aws_security_group" "web_server_security_group" {
  name = "${var.cluster_name}-sg-web-server"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_http_inbound_web_server" {
  type = "ingress"
  security_group_id = "${aws_security_group.web_server_security_group.id}"

  from_port = "${var.web_server_port}"
  to_port = "${var.web_server_port}"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "load_balancer_security_group" {
  name = "${var.cluster_name}-sg-elb"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_http_inbound_lb" {
  type = "ingress"
  security_group_id = "${aws_security_group.load_balancer_security_group.id}"

  from_port = "${var.lb_server_port}"
  to_port = "${var.lb_server_port}"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = "${aws_security_group.load_balancer_security_group.id}"

  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_launch_configuration" "web_server_launch_config" {
  image_id = "ami-40d28157"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.web_server_security_group.id}"]

  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_server_auto_scaling_group" {
  launch_configuration = "${aws_launch_configuration.web_server_launch_config.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  min_size = "${var.cluster_min_size}"
  max_size = "${var.cluster_max_size}"

  load_balancers = ["${aws_elb.web_server_load_balancer.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}

resource "aws_elb" "web_server_load_balancer" {
  name = "${var.cluster_name}-elb"
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
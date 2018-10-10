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
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.web_server_security_group.id}"]

  name = "launch-config"

  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_server_auto_scaling_group" {
  // Name depends on launch config name, so when launch config changes (with a deployment of a new AMI, for instance),
  // the autoscaling group must update as well.
  name = "${var.cluster_name}-${aws_launch_configuration.web_server_launch_config.name}-asg"

  launch_configuration = "${aws_launch_configuration.web_server_launch_config.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  min_size = "${var.cluster_min_size}"
  max_size = "${var.cluster_max_size}"
  // Make sure new instances are up and registered with the ELB before terraform destroys the old ASG
  min_elb_capacity = "${var.cluster_min_size}"

  load_balancers = ["${aws_elb.web_server_load_balancer.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "${var.cluster_name}"
    propagate_at_launch = true
  }

  // Create a new ASG before destroying
  lifecycle {
    create_before_destroy = true
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = "${var.enable_autoscaling}"

  scheduled_action_name = "scale-out-during-business-hours"
  autoscaling_group_name = "${aws_autoscaling_group.web_server_auto_scaling_group.name}"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = "${var.enable_autoscaling}"

  scheduled_action_name = "scale-in-at-night"
  autoscaling_group_name = "${aws_autoscaling_group.web_server_auto_scaling_group.name}"
  min_size = 2
  max_size = 2
  desired_capacity = 2
  recurrence = "0 17 * * *"
}

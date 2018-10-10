output "lb_dns_name" {
  value = "${aws_elb.web_server_load_balancer.dns_name}"
}

output "auto_scaling_group_name" {
  value = "${aws_autoscaling_group.web_server_auto_scaling_group.name}"
}

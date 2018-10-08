output "web_ip" {
  value = "${aws_elb.web_server_load_balancer.dns_name}"
}
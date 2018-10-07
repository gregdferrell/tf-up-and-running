output "web_ip" {
  value = "${aws_instance.web_server_instance.public_ip}"
}
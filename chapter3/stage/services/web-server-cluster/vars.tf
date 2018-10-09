variable "state_bucket" {
  default = "gregdferrell-tf-up-and-running-state-ch3"
}

variable "aws_region" {
  description = "aws region"
  default = "us-east-1"
}

variable "web_server_port" {
  description = "web server HTTP port"
  default = 8080
}

variable "lb_server_port" {
  description = "web server HTTP port"
  default = 80
}

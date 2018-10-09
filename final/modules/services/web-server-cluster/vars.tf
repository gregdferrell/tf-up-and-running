variable "db_remote_state_bucket" {
  description = "the name of the S3 bucket for the DB's remote state"
}

variable "db_remote_state_key" {
  description = "the path for the DB's remote state in S3"
}

variable "aws_region" {
  description = "aws region"
}

variable "cluster_name" {
  description = "the name to use for all the cluster resources"
}

variable "web_server_port" {
  description = "web server HTTP port"
}

variable "lb_server_port" {
  description = "web server HTTP port"
}

variable "instance_type" {
  description = "the EC2 instance type to run"
}

variable "cluster_min_size" {
  description = "the minimum number of EC2 instances in the ASG"
}

variable "cluster_max_size" {
  description = "the maximum number of EC2 instances in the ASG"
}

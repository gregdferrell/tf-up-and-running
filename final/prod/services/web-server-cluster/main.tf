// Setup Remote State using S3 bucket created in "global" proj
terraform {
  backend "s3" {
    bucket = "gregdferrell-tf-up-and-running-state"
    key = "state/prod/services/web-server-cluster/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "tf-up-and-running-app-state"
  }
}

// Provider
provider "aws" {
  region = "${var.aws_region}"
}

// Resources
module "web_server_cluster" {
  source = "../../../modules/services/web-server-cluster"

  db_remote_state_bucket = "gregdferrell-tf-up-and-running-state"
  db_remote_state_key = "state/prod/data-stores/mysql/terraform.tfstate"
  aws_region = "${var.aws_region}"
  cluster_name = "tf-up-and-running-prod"
  web_server_port = 8080
  lb_server_port = 80
  instance_type = "t2.micro"
  cluster_min_size = 2
  cluster_max_size = 10
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  autoscaling_group_name = "${module.web_server_cluster.auto_scaling_group_name}"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  autoscaling_group_name = "${module.web_server_cluster.auto_scaling_group_name}"
  min_size = 2
  max_size = 2
  desired_capacity = 2
  recurrence = "0 17 * * *"
}

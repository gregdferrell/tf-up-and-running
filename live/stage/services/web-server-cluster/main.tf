// Setup Remote State using S3 bucket created in "global" proj
terraform {
  backend "s3" {
    bucket = "gregdferrell-tf-up-and-running-state"
    key = "state/stage/services/web-server-cluster/terraform.tfstate"
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
  source = "../../../../modules/services/web-server-cluster"

  db_remote_state_bucket = "gregdferrell-tf-up-and-running-state"
  db_remote_state_key = "state/stage/data-stores/mysql/terraform.tfstate"
  aws_region = "${var.aws_region}"
  cluster_name = "tf-up-and-running"
  web_server_port = 8080
  lb_server_port = 80
  instance_type = "t2.micro"
  cluster_min_size = 2
  cluster_max_size = 2
}

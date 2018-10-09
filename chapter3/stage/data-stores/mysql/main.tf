// Setup Remote State using S3 bucket created by bootstrap proj
terraform {
  backend "s3" {
    bucket = "gregdferrell-tf-up-and-running-state-ch3"
    key = "state/stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "tf-up-and-running-app-state-ch3"
  }
}

// Provider
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_db_instance" "mysql_db" {
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "tfupandrunning"
  username = "admin"
  password = "${var.db_password}"
}

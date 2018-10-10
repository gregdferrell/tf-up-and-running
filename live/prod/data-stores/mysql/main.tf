// Setup Remote State using S3 bucket created in "global" proj
terraform {
  backend "s3" {
    bucket = "gregdferrell-tf-up-and-running-state"
    key = "state/prod/data-stores/mysql/terraform.tfstate"
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
module "mysql" {
  source = "../../../../modules/data-stores/mysql"

  aws_region = "${var.aws_region}"
  db_instance_type = "db.t2.micro"
  db_name = "MySqlProdDb"
  db_username = "admin"
  db_password = "ijklmnop"
}

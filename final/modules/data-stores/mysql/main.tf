// Provider
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_db_instance" "mysql_db" {
  engine = "mysql"
  allocated_storage = 10
  instance_class = "${var.db_instance_type}"
  name = "${var.db_name}"
  username = "${var.db_username}"
  password = "${var.db_password}"
  skip_final_snapshot = true
}

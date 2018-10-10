output "db_name" {
  value = "${aws_db_instance.mysql_db.name}"
}

output "db_address" {
  value = "${aws_db_instance.mysql_db.address}"
}

output "db_port" {
  value = "${aws_db_instance.mysql_db.port}"
}

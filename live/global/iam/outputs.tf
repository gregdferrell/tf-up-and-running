output "user_arns" {
  value = "${aws_iam_user.example_users.*.arn}"
}

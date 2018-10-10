// Setup Remote State using S3 bucket created in "global" proj
terraform {
  backend "s3" {
    bucket = "gregdferrell-tf-up-and-running-state"
    key = "state/global/iam/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "tf-up-and-running-app-state"
  }
}

// Provider
provider "aws" {
  region = "us-east-1"
}

// Data Sources
data "aws_iam_policy_document" "ec2_read_only" {
  statement {
    effect = "Allow"
    actions = ["ec2:Describe*"]
    resources = ["*"]
  }
}

// Resources
resource "aws_iam_user" "example_users" {
  count = "${length(var.user_names)}"
  name = "${element(var.user_names, count.index)}"
}

resource "aws_iam_policy" "ec2_read_only" {
  name = "ec2-read-only"
  policy = "${data.aws_iam_policy_document.ec2_read_only.json}"
}

resource "aws_iam_user_policy_attachment" "ec2_access" {
  count = "${length(var.user_names)}"
  user = "${element(aws_iam_user.example_users.*.name, count.index)}"
  policy_arn = "${aws_iam_policy.ec2_read_only.arn}"
}

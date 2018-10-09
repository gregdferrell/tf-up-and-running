provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket_terraform_state" {
  bucket = "gregdferrell-tf-up-and-running-state-ch3"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name = "tf-up-and-running-app-state-ch3"
  hash_key = "LockID"
  read_capacity = 1
  write_capacity = 1

  "attribute" {
    name = "LockID"
    type = "S"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_instance" "example" {
  ami           = "ami-40d28157"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet.id}"

  tags {
    Name = "terraform-example"
  }
}

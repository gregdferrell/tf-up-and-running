provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web_server_instance" {
  ami           = "ami-40d28157"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World!" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  vpc_security_group_ids = ["${aws_security_group.web_server_sg.id}"]

  tags {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "web_server_sg" {
  name = "webserver security group"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

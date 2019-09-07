provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "webserver" {
  ami           = "ami-0f2b4fc905b0bd1f1"
  instance_type = "t2.micro"

  tags = {
    Name = "DarkCityWeb01"
  }
}

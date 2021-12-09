provider "aws" {
    region = "us-west-1"   
}

variable "ip" {
  type = string
}


data "aws_ami" "latest" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "key" {
    key_name = "server-key"
    public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "my-sg" {
  name        = "my-sg"
  description = "my-sg"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description      = "From specific IP"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.ip]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-sg"
  }
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "my-subnet" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "us-west-1b"

  tags = {
    Name = "my-subnet"
  }
}

resource "aws_internet_gateway" "my-ig" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-ig" 
  }
}

resource "aws_default_route_table" "default-route" {
  default_route_table_id = aws_vpc.my-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-ig.id
  }
}

resource "aws_instance" "server" {
    ami = data.aws_ami.latest.id
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.my-sg.id]
    subnet_id = aws_subnet.my-subnet.id
    associate_public_ip_address = true
    key_name = aws_key_pair.key.key_name
    availability_zone = "us-west-1b"

    tags = {
        Name = "my-server"
    }
}

output "server_ip" {
  value = "${aws_instance.server.public_ip}"
}
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.38.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_vpc" "My-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My-vpc"
  }
}

resource "aws_subnet" "pub-sub1" {
  vpc_id     = aws_vpc.My-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1"

  tags = {
    Name = "My-vpc-pub-sub1"
  }
}

resource "aws_subnet" "pri-sub" {
  vpc_id     = aws_vpc.My-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2"

  tags = {
    Name = "My-vpc-pri-sub"
  }
}

resource "aws_subnet" "pri-sub2" {
  vpc_id     = aws_vpc.My-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-3"

  tags = {
    Name = "My-vpc-pri-sub2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.My-vpc.id

  tags = {
    Name = "My-vpc-IGW"
  }
}

resource "aws_route_table" "My-pubroute" {
  vpc_id = aws_vpc.My-vpc.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "My-vpc-gw"
  }
}

resource "aws_route_table_association" "Pubsubasso" {
  subnet_id      = aws_subnet.pub-sub1.id
  route_table_id = aws_route_table.My-pubroute.id
}

resource "aws_route_table" "My-priroute" {
  vpc_id = aws_vpc.My-vpc.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "My-vpc-gw"
  }
}

resource "aws_route_table_association" "Pri1subasso" {
  subnet_id      = aws_subnet.pri-sub.id
  route_table_id = aws_route_table.My-priroute.id
}

resource "aws_route_table_association" "Pri2subasso" {
  subnet_id      = aws_subnet.pri-sub2.id
  route_table_id = aws_route_table.My-priroute.id
}

resource "aws_security_group" "allow_all_TCP" {
  name        = "allow_all_TCP"
  description = "Allow all TCP inbound traffic"
  vpc_id      = aws_vpc.My-vpc.id

  tags = {
    Name = "allow_all_TCP"
  }
}

  ingress {
    description       = "TLS from VPC"
    from_port         = 22
    to_port           = 100
    protocol          = "tcp"
    cidr_block        = {"0.0.0.0/0"}
  }

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_block        = {"0.0.0.0/0"}
    ipv6_cidr_block   = {"::/0"}
  }

  tags ={
    Name ="allow_all_TCP"
  }

resource "aws_instance" "instance1" {
  ami                      = "ami-023eb5c021738c6d0"
  instance_type            = "t2.micro"
  subnet_id                = aws_subnet.pri-sub.id
  vpc_security_group_ids   = ["aws_security_group.allow_all_TCP"]
  availability_zone        = "ap-southeast-2"
  tags = {
    Name = "instance1"
  }
}

resource "aws_instance" "instance2" {
  ami                      = "ami-023eb5c021738c6d0"
  instance_type            = "t2.micro"
  subnet_id                = aws_subnet.pub-sub1.id
  vpc_security_group_ids   = ["aws_security_group.allow_all_TCP"]
  availability_zone        = "ap-southeast-2"
  tags = {
    Name = "instance2"
  }
}
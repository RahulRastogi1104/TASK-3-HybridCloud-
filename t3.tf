provider "aws" {
  region     = "ap-south-1"
  profile    = "myrahul"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}
module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  key_name   = "task3key"
  public_key = tls_private_key.this.public_key_openssh
}


variable "enter_ur_key_name" {
	type = string
	default = "task3key"
}


resource "aws_vpc" "VPC" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support  = true
 
  tags = {
    Name = "VPC"
  }
}



resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true


 depends_on = [
 aws_vpc.VPC
]

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  
depends_on = [
 aws_vpc.VPC
]

tags = {
    Name = "private_subnet"
  }
}   


resource "aws_internet_gateway" "VPC_internet_gateway" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "VPC_internet_gateway"
  }

depends_on = [
 aws_vpc.VPC
]
}


resource "aws_route_table" "RoutingTable" {
  vpc_id = aws_vpc.VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_internet_gateway.id
  }

  tags = {
    Name = "RoutingTable"
  }
}

resource "aws_route_table_association" "Association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.RoutingTable.id
}


resource "aws_security_group" "sec_gp-01" {
  description = "allow SSH & HTTP"
  name = "sec_gp-01"
  vpc_id = aws_vpc.VPC.id

  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Name= "sec_gp-01"
  }

}


resource "aws_security_group" "sec_gp-02" {
  name = "sec_gp-02"
  description = "allow only instances who have sec_gp-01 security group"
  vpc_id = aws_vpc.VPC.id

  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.sec_gp-01.id]
  }


 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Name= "sec_gp-02"
  }

}


 resource "aws_instance" "WP_instance" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.sec_gp-01.id]
  key_name = "task3key"

 depends_on = [
  aws_security_group.sec_gp-01
  ]

 tags ={
    Name= "WordPress_instance"
  }

}


resource "aws_instance" "MySQL_instance" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sec_gp-02.id]
  key_name = "task3key"
 
depends_on = [
  aws_security_group.sec_gp-02
  ]

 tags ={
    Name= "MySQL_Server"
  }
}
  

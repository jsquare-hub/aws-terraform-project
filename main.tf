variable "my_access_key" {}
variable "my_secret_key" {}
variable "my_region" {}
variable "vpc_cidr" {}
variable "cidr_pub_1a" {}
variable "cidr_pub_1b" {}
variable "cidr_pri_1a" {}
variable "cidr_pri_1b" {}
variable "machine_ip" {}
variable "ec2_ip" {}
variable "ec2_ami" {}
variable "ec2_type" {}
variable "ec2_key_name" {}

provider "aws" {
  access_key = var.my_access_key
  secret_key = var.my_secret_key
  region     = var.my_region
}

resource "aws_vpc" "jag-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "vpc-jag"
  }
}

# availability-zone "us-east-1b" -cidr-block "10.0.1.144/28"
resource "aws_subnet" "pub-1a" {
  vpc_id            = aws_vpc.jag-vpc.id
  cidr_block        = var.cidr_pub_1a
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public-1a"
  }
}

resource "aws_subnet" "pub-1b" {
  vpc_id            = aws_vpc.jag-vpc.id
  cidr_block        = var.cidr_pub_1b
  availability_zone = "us-east-1b"
  tags = {
    Name = "Public-1b"
  }
}

resource "aws_subnet" "pri-1a" {
  vpc_id            = aws_vpc.jag-vpc.id
  cidr_block        = var.cidr_pri_1a
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private-1a"
  }
}

resource "aws_subnet" "pri-1b" {
  vpc_id            = aws_vpc.jag-vpc.id
  cidr_block        = var.cidr_pri_1b
  availability_zone = "us-east-1b"
  tags = {
    Name = "Private-1b"
  }
}

# IG gateway creation:
resource "aws_internet_gateway" "IG" {
  vpc_id = aws_vpc.jag-vpc.id
  tags = {
    Name = "Jag-IG"
  }
}

# Create custom route table
resource "aws_route_table" "pub-route" {
  vpc_id = aws_vpc.jag-vpc.id

  # Internet access (IPv4)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IG.id
  }

  tags = {
    Name = "route_table_to_public_internet"
  }
}

# 5. Associate a subnet with route table
resource "aws_route_table_association" "pub-1a_ass" {
  subnet_id      = aws_subnet.pub-1a.id
  route_table_id = aws_route_table.pub-route.id
}

resource "aws_route_table_association" "pub-1b_ass" {
  subnet_id      = aws_subnet.pub-1b.id
  route_table_id = aws_route_table.pub-route.id
}

# Create a security group and inbound/outbound rules
resource "aws_security_group" "jag-SG" {
  name        = "jag-public-sg"
  description = "Allow SSH, HTTP"
  vpc_id      = aws_vpc.jag-vpc.id

  # Inbound rules
  ingress {
    description  = "SSH"
    from_port    = 22
    to_port      = 22
    protocol     = "tcp"
    cidr_blocks  = [var.machine_ip]
  }

  ingress {
    description  = "HTTPS"
    from_port    = 80
    to_port      = 80
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jag-security-grp"
  }
}

# Create a network interface with an IP in the private-subnet 
resource "aws_network_interface" "ec2-nic" {
  subnet_id       = aws_subnet.pri-1a.id
  private_ips     = [var.ec2_ip]
  security_groups = [aws_security_group.jag-SG.id]
}

# Assign an elastic IP to the nic
resource "aws_eip" "ec2_eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.ec2-nic.id
  associate_with_private_ip = var.ec2_ip
  depends_on                = [aws_internet_gateway.IG, aws_instance.postgres-server] # Add this line to wait for instance creation
}

resource "aws_instance" "postgres-server" {
  ami               = var.ec2_ami
  instance_type     = var.ec2_type
  availability_zone = "us-east-1a"
  key_name          = var.ec2_key_name

  primary_network_interface {
    # device_index         = 0
    network_interface_id = aws_network_interface.ec2-nic.id
  }

  tags = {
    Name = "my-postgresql-server"
  }
}

variable "my_access_key" {}
variable "my_secret_key" {}
variable "my_region" {}
variable "vpc_cidr" {}
variable "cidr_pub_1a" {}
variable "cidr_pub_1b" {}
variable "cidr_pri_1a" {}
variable "cidr_pri_1b" {}


provider "aws" {
  access_key = var.my_access_key
  secret_key = var.my_secret_key
  region = var.my_region
}

resource "aws_vpc" "jag-vpc" {
    cidr_block = var.vpc_cidr

    tags = {Name = "vpc-jag"}
}

# availability-zone "us-east-1b" -cidr-block "10.0.1.144/28"
resource "aws_subnet" "pub-1a" {
    vpc_id = aws_vpc.jag-vpc.id
    cidr_block = var.cidr_pub_1a
    availability_zone = "us-east-1a"
    tags = {Name = "Public-1a" }
}

resource "aws_subnet" "pub-1b" {
    vpc_id = aws_vpc.jag-vpc.id
    cidr_block = var.cidr_pub_1b
    availability_zone = "us-east-1b"
    tags = {Name = "Public-1b" }
}

resource "aws_subnet" "pri-1a" {
    vpc_id = aws_vpc.jag-vpc.id
    cidr_block = var.cidr_pri_1a
    availability_zone = "us-east-1a"
    tags = {Name = "Private-1a" }
}

resource "aws_subnet" "pri-1b" {
    vpc_id = aws_vpc.jag-vpc.id
    cidr_block = var.cidr_pri_1b
    availability_zone = "us-east-1b"
    tags = {Name = "Private-1b" }
}
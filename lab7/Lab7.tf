provider "aws" {
  region     = "us-east-2"
  access_key = var.accesskey
  secret_key = var.secretkey
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "Labaratorna7_VPC"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"


  tags = {
    "Name" = "Labaratorna7_Subnet"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2b"



  tags = {
    "Name" = "Lab7_Subnet2"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Labaratorna7_Gateway"
  }
}

resource "aws_route_table" "routetbl" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "Labaratorna7_Route_Table"
  }
}

resource "aws_route_table_association" "routetbl1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routetbl.id
}

resource "aws_route_table_association" "routetbl2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routetbl.id
}

resource "aws_network_acl" "acl" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    protocol   = -1
    rule_no    = 200
    action     = "deny"
    cidr_block = "50.31.252.0/24"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_security_group" "db_SG" {
  name   = "Labaratorna7_SG"
  vpc_id = aws_vpc.main_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Labaratorna7_SG"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "subnet_group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "Labaratorna7_DB_subnet_grp"
  }
}

resource "aws_db_instance" "rds_db" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "dbtest"
  username               = "testuser"
  password               = "Lgfd!53Kjst34"
  publicly_accessible    = true
  skip_final_snapshot    = true
  parameter_group_name   = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.db_SG.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
}

provider "aws" {
  region     = "us-east-2"
  access_key = var.accesskey
  secret_key = var.secretkey
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "Lab6SG" {

  name   = "Lab6SG"
  vpc_id = "vpc-963187fd"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab6SG"
  }

}

resource "aws_lb" "lb" {
  name               = "Lab6-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Lab6SG.id]
  subnets            = ["subnet-83acd3cf", "subnet-c1924baa", "subnet-781d0a02"]
}

resource "aws_instance" "ec2" {
  count                   = 2
  ami                     = "ami-0343573294f83fd67"
  instance_type           = var.instance
  key_name                = var.keypair
  disable_api_termination = true
  security_groups         = [aws_security_group.Lab6SG.name]

  tags = {
    Name = format("Instance-%d", count.index)
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "Lab6-TG"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-963187fd"
}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count            = length(aws_instance.ec2)
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.ec2[count.index].id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

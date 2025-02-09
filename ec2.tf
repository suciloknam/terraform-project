resource "aws_security_group" "alb_sg" {
  # ... other configuration ...connection
  name =  "pok_alb_sg"
  description = "security group"
  vpc_id = aws_vpc.local_vpc.id

  ingress = {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pok_alb_sg"
  }

}

resource "aws_security_group" "ec2_sg" {
  # ... other configuration ...connection
  name =  "pok_ec2_sg"
  description = "security group"
  vpc_id = aws_vpc.local_vpc.id

  ingress = {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pok_ec2_sg"
  }

}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnet1[*].id 
  depends_on         = [ aws_internet_gateway.gw ]

}

resource "aws_lb_target_group" "test_target" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.local_vpc.id
  tags = {
    "Name" = "pok-tf-example-lb-tg"
  }
}
resource "aws_lb_listener" "test_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test_target.arn
  }
  tags = {
    "Name" = "pok-test-listener"
  }
}

resource "aws_launch_template" "ec2_launch_template" {
  name = "pok_web_server"
  image_id = "ami-085ad6ae776d8f09c"
  instance_type = "t2.micro"
  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.ec2_sg.id]
  }
  
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ec2_lauch_template"
    }
  }

  user_data = filebase64("userdata.sh")
}
resource "aws_autoscaling_group" "ec2_autoscaling_group" {
  name = "pok_autoscaling_group"
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  target_group_arns = [aws_lb_target_group.test_target.arn]
  vpc_zone_identifier = [aws_subnet.private_subnet1[*].id]
  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }
    health_check_type = "EC2"
}

output "alb_dns_name" {
  value = aws_lb.test.dns_name
}

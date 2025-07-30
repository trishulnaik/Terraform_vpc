resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = { "Name" = var.vpc_name }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# created subnets (public subnet)
resource "aws_subnet" "subnet_public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs.public_a
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "subnet_public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs.public_b
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}
# (private subnet)
resource "aws_subnet" "subnet_private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs.private_a
  availability_zone = "us-east-1a"
}
resource "aws_subnet" "subnet_private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs.private_b
  availability_zone = "us-east-1b"
}

# public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
resource "aws_route_table_association" "public_a_association" {
  route_table_id = aws_route_table.public_rt.id #mandatory
  subnet_id      = aws_subnet.subnet_public_1.id
}
resource "aws_route_table_association" "public_b_association" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.subnet_public_2.id
}


#EIP for the nat gatways
resource "aws_eip" "nat_eip_a" {
    domain = "vpc"
}
resource "aws_eip" "nat_eip_b" {
    domain = "vpc"
}

#Nat gateways for the private subnet
resource "aws_nat_gateway" "nat_gw_a" {
    subnet_id = aws_subnet.subnet_public_1.id #mandatory
    allocation_id = aws_eip.nat_eip_a.id
    depends_on = [aws_internet_gateway.gw]
}
resource "aws_nat_gateway" "nat_gw_b" {
    subnet_id = aws_subnet.subnet_public_2.id #mandatory
    allocation_id = aws_eip.nat_eip_b.id
    depends_on = [ aws_internet_gateway.gw ]
}

# Private Route Tables
resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.main.id
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_a.id
  }
}
resource "aws_route_table" "private_rt_b" {
  vpc_id = aws_vpc.main.id
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_b.id
  }
}
## association of Private Route tables
resource "aws_route_table_association" "private_rt_a_associ" {
  route_table_id = aws_route_table.private_rt_a.id
  subnet_id = aws_subnet.subnet_private_1.id
}
resource "aws_route_table_association" "private_rt_b_associ" {
  route_table_id = aws_route_table.private_rt_b.id
  subnet_id = aws_subnet.subnet_private_2.id
}



# Security Groups
## for the alb
resource "aws_security_group" "alb_security" {
  vpc_id = aws_vpc.main.id
  name = "alb_security"

}
resource "aws_vpc_security_group_ingress_rule" "alb_inbound" {
  security_group_id = aws_security_group.alb_security.id
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = "0.0.0.0/0"
}
resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  security_group_id = aws_security_group.alb_security.id
  ip_protocol = "-1"
  from_port = 0
  to_port = 0
  cidr_ipv4 = "0.0.0.0/0"
}
## for launch template ec2 instances
resource "aws_security_group" "asg_security" {
  vpc_id = aws_vpc.main.id
  name = "asg_web_security"
}
resource "aws_vpc_security_group_ingress_rule" "asg_inbound_http" {
  security_group_id = aws_security_group.asg_security.id
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  referenced_security_group_id = aws_security_group.alb_security.id # only allow traffic from alb sg
}
resource "aws_vpc_security_group_ingress_rule" "asg_inbound_ssh" {
  security_group_id = aws_security_group.asg_security.id
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_ipv4 = "0.0.0.0/0"
}
resource "aws_vpc_security_group_egress_rule" "asg_outbound" {
  security_group_id = aws_security_group.asg_security.id
  ip_protocol = "-1"
  from_port = 0
  to_port = 0
  cidr_ipv4 = "0.0.0.0/0"
}

# ALB
resource "aws_lb" "main_alb" {
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.subnet_public_1.id, aws_subnet.subnet_public_2.id]
  security_groups = [aws_security_group.alb_security.id]
}
## alb target group
resource "aws_lb_target_group" "alb_target_group" {
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  health_check {
    path = "/"
    protocol = "HTTP"
    port = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 300
    matcher             = "200" #ok status
  }
}
## alb listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# ASG
## launch template to create the ASG
resource "aws_launch_template" "asg_launch_template" {
  name_prefix = "trishul-web-server"
  image_id = "ami-0ec18f6103c5e0491"
  instance_type = var.instance_type
  # security_group_names = [aws_security_group.asg_security.id]
  vpc_security_group_ids = [aws_security_group.asg_security.id]
  user_data = base64encode(file("main.sh"))
}
# asg
resource "aws_autoscaling_group" "asg_group" {
  name = "trishul_asg"
  max_size = var.asg_capacity.max_size
  min_size = var.asg_capacity.min_size
  desired_capacity = var.asg_capacity.desired_capacity
  vpc_zone_identifier = [aws_subnet.subnet_private_1.id, aws_subnet.subnet_private_2.id]
  health_check_type = "EC2"
  health_check_grace_period = 300
  launch_template {
    id = aws_launch_template.asg_launch_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.alb_target_group.arn] # attach asg to alb target group
}
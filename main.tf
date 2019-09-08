##################
#                #
# PROVIDER       #
#                #
##################

provider "aws" {
  region = "us-east-2"
}

##################
#                #
# VARS           #
#                #
##################

variable "server_port" {
	description = "Webserver HTTP port"
	type        = number
	default     = 8080
}

variable "web_server_ami" {
	description = "AMI to run on webserver"
	type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "web_server_instance_type" {
	description = "AWS Server Class to use for webserver"
	type        = string
	default     = "t2.micro"
}

variable "web_server_start_script" {
	description = "Script to start webserver"
	type        = string
	default     = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p $(var.server_port)  &
              EOF
}

##################
#                #
# DATA           #
#                #
##################

data "aws_vpc" "default" {
	default = true
}

data "aws_subnet_ids" "default" {
	vpc_id = data.aws_vpc.default.id
}

##################
#                #
# RESOURCES      #
#                #
##################

# SG

resource "aws_security_group" "allow-http" {
	name = "darkcitywebsever"

	ingress {
		from_port   = var.server_port
		to_port     = var.server_port
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
		Name = "darkcityweb-sg"
	}

}

# LC

resource "aws_launch_configuration" "webcluster-lc" {
	image_id        = var.web_server_ami
	instance_type   = var.web_server_instance_type
  security_groups = [aws_security_group.allow-http.id]
	user_data       = var.web_server_start_script
}

# ASG

resource "aws_autoscaling_group" "webcluster-asg" {
	launch_configuration = aws_launch_configuration.webcluster-lc.name
	vpc_zone_identifier  = data.aws_subnet_ids.default.ids
	target_group_arns    = [aws_lb_target_group.web-cluster-asg.arn]
	health_check_type    = "ELB"
	
	min_size = 2
	max_size = 10

	tag {
		key                 = "Name"
		value               = "DarkCityWeb"
		propagate_at_launch = true
	}
	
	lifecycle {
		create_before_destroy = true
	}
}

# ALB

resource "aws_lb" "darkcityagent-dot-com" {
	name               = "darkcityagent-dot-com"
	load_balancer_type = "application"
	subnets            = data.aws_subnet_ids.default.ids
	security_groups    = [aws_security_group.http-alb.id]
}

resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.darkcityagent-dot-com.arn
	port							= 80
	protocol          = "HTTP"
  
	default_action {
		type = "fixed-response"

		fixed_response {
			content_type = "text/plain"
			message_body = "404: Page not found"
			status_code  = 404
		}
	}
}

resource "aws_security_group" "http-alb" {
	name = "http-alb"
  
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
}

resource "aws_lb_target_group" "web-cluster-asg" {
	name     = "terraform-asg-example"
  port     = var.server_port
	protocol = "HTTP"
	vpc_id   = data.aws_vpc.default.id

	health_check {
		path                = "/"
		protocol            = "HTTP"
		matcher             = "200"
		interval            = 15
		timeout             = 3
		healthy_threshold   = 2
		unhealthy_threshold = 2
	}
}

resource "aws_lb_listener_rule" "web-cluster-asg" {
	listener_arn = aws_lb_listener.http.arn
	priority     = 100

	condition {
		field  = "path-pattern"
    values = ["*"]
	}

	action {
		type = "forward"
		target_group_arn = aws_lb_target_group.web-cluster-asg.arn
	}
}

##################
#                #
# OUTPUTS        #
#                #
##################

output "alb_dns_name" {
	value = aws_lb.darkcityagent-dot-com.dns_name
}

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
	name = "darkcityweb-sg"

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


##################
#                #
# OUTPUTS        #
#                #
##################


# Task 3: High Availability + Auto Scaling
# Migrate to ALB + ASG in private subnets

provider "aws" {
  region = "us-east-1"
}

variable "student_name" {
  default = "Samiksha_Patel"
}

locals {
  name_prefix = "${var.student_name}_"
}

# Get VPC and subnets from Task 1
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${local.name_prefix}VPC"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["${local.name_prefix}Public-Subnet-1", "${local.name_prefix}Public-Subnet-2"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${local.name_prefix}Private-Subnet-1", "${local.name_prefix}Private-Subnet-2"]
  }
}

# 1. Security Group for ALB (allows HTTP from anywhere)
resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}ALB-SG"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
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
    Name = "${local.name_prefix}ALB-Security-Group"
  }
}

# 2. Security Group for EC2 instances (allows HTTP only from ALB)
resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}App-SG"
  description = "Security group for application instances"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow SSH from anywhere (for troubleshooting - restrict in production)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
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
    Name = "${local.name_prefix}App-Security-Group"
  }
}

# 3. Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "samiksha-patel-Web-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = {
    Name = "${local.name_prefix}Application-Load-Balancer"
  }
}

# 4. ALB Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "samiksha-patel-Web-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health.html"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "samiksha-patel-Web-TG"
  }
}

# 5. ALB Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }

  tags = {
    Name = "${local.name_prefix}ALB-HTTP-Listener"
  }
}

# 6. Launch Template for EC2 instances
resource "aws_launch_template" "web_lt" {
  name_prefix   = "${local.name_prefix}Web-LT"
  image_id      = "ami-0b0dcb5067f052a63"  # Amazon Linux 2023
  instance_type = "t3.micro"
  key_name      = ""  # No SSH key needed for web servers

  network_interfaces {
    associate_public_ip_address = false  # Instances in private subnet
    security_groups             = [aws_security_group.app_sg.id]
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 8
      volume_type = "gp2"
      encrypted   = true
    }
  }

      user_data = base64encode(<<-EOF
              #!/bin/bash
              
              # Update system
              sudo yum update -y
              
              # Install Nginx
              sudo amazon-linux-extras install nginx1 -y
              
              # Start Nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              
              # Create website with static content
              sudo cat > /usr/share/nginx/html/index.html <<'HTML_EOF'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>High Availability Website</title>
                  <style>
                      body { font-family: Arial, sans-serif; margin: 40px; }
                      .container { max-width: 800px; margin: auto; padding: 20px; border: 1px solid #ddd; }
                      .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
                      .info { background: #f9f9f9; padding: 15px; margin: 15px 0; }
                      .success { color: #4CAF50; font-weight: bold; }
                      .instance { background: #e8f4ff; padding: 10px; margin: 10px 0; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <div class="header">
                          <h1>High Availability Website</h1>
                          <p>Auto Scaling Group with Application Load Balancer</p>
                      </div>
                      
                      <div class="info">
                          <h2>Architecture Overview</h2>
                          <div class="instance">
                              <h3>✓ Application Load Balancer</h3>
                              <p>Distributes traffic across multiple instances</p>
                          </div>
                          <div class="instance">
                              <h3>✓ Auto Scaling Group</h3>
                              <p>Maintains 2-4 instances across availability zones</p>
                          </div>
                          <div class="instance">
                              <h3>✓ Private Subnets</h3>
                              <p>Instances deployed in private subnets for security</p>
                          </div>
                          <div class="instance">
                              <h3>✓ Health Checks</h3>
                              <p>Automatic health monitoring and replacement</p>
                          </div>
                      </div>
                      
                      <div class="info">
                          <h2>Deployment Details</h2>
                          <ul>
                              <li><strong>Infrastructure as Code:</strong> Terraform</li>
                              <li><strong>Web Server:</strong> Nginx</li>
                              <li><strong>Instance Type:</strong> t3.micro</li>
                              <li><strong>AMI:</strong> Amazon Linux 2023</li>
                              <li><strong>High Availability:</strong> Multi-AZ deployment</li>
                              <li><strong>Security:</strong> Private subnets, Security Groups</li>
                          </ul>
                      </div>
                      
                      <div class="info">
                          <p class="success">✅ This website is served from a highly available architecture</p>
                          <p class="success">✅ Traffic is automatically load balanced</p>
                          <p class="success">✅ Instances auto-scale based on demand</p>
                          <p class="success">✅ Health checks ensure only healthy instances receive traffic</p>
                      </div>
                  </div>
              </body>
              </html>
              HTML_EOF
              
              # Create health check page
              echo "Healthy" | sudo tee /usr/share/nginx/html/health.html
              
              # Restart Nginx
              sudo systemctl restart nginx
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name_prefix}HA-WebServer"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${local.name_prefix}HA-WebServer-Volume"
    }
  }

  tags = {
    Name = "${local.name_prefix}Web-Launch-Template"
  }
}

# 7. Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name_prefix          = "samiksha-patel-Web-ASG"
  vpc_zone_identifier  = data.aws_subnets.private.ids
  target_group_arns    = [aws_lb_target_group.web_tg.arn]
  health_check_type    = "ELB"
  desired_capacity     = 2
  min_size             = 2
  max_size             = 4

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  # Instance refresh to update instances when launch template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}HA-WebServer"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Assessment"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 8. Auto Scaling Policies (optional - for scaling based on metrics)
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.name_prefix}Scale-Up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.name_prefix}Scale-Down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# Outputs
output "alb_dns_name" {
  value       = aws_lb.web_alb.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "alb_url" {
  value       = "http://${aws_lb.web_alb.dns_name}"
  description = "URL to access the website via ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.web_tg.arn
  description = "ARN of the target group"
}

output "asg_name" {
  value       = aws_autoscaling_group.web_asg.name
  description = "Name of the Auto Scaling Group"
}

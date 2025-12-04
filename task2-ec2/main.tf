# Task 2: EC2 Static Website Hosting
# Deploy resume website on EC2 with Nginx in public subnet

provider "aws" {
  region = "us-east-1"
}

variable "student_name" {
  default = "Samiksha_Patel"
}

locals {
  name_prefix = "${var.student_name}_"
}

# Get the VPC and subnet IDs from Task 1
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${local.name_prefix}VPC"]
  }
}

data "aws_subnet" "public_1" {
  filter {
    name   = "tag:Name"
    values = ["${local.name_prefix}Public-Subnet-1"]
  }
}

# 1. Security Group for EC2 instance
resource "aws_security_group" "web_sg" {
  name        = "${local.name_prefix}Web-SG"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = data.aws_vpc.main.id

  # SSH access from anywhere
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}Web-Security-Group"
  }
}

# 2. EC2 Instance (Free Tier eligible: t2.micro)
resource "aws_instance" "web_server" {
  ami                    = "ami-0b0dcb5067f052a63" # Amazon Linux 2023 AMI - Free Tier eligible
  instance_type          = "t3.micro"              # Free Tier eligible
  subnet_id              = data.aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  # User data script - runs on first boot
  user_data = <<-EOF
              #!/bin/bash
              
              # Update system packages
              sudo yum update -y
              
              # Install Nginx
              sudo amazon-linux-extras install nginx1 -y
              
              # Start Nginx service
              sudo systemctl start nginx
              sudo systemctl enable nginx
              
              # Create resume website
              sudo cat > /usr/share/nginx/html/index.html <<'HTML_EOF'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Samiksha Patel - Resume</title>
                  <style>
                      body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
                      .container { max-width: 800px; margin: auto; padding: 20px; }
                      header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
                      section { margin: 20px 0; padding: 20px; background: #f9f9f9; }
                      h2 { color: #4CAF50; }
                      .skills span { background: #4CAF50; color: white; padding: 5px 10px; margin: 5px; display: inline-block; border-radius: 3px; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <header>
                          <h1>Samiksha Patel</h1>
                          <p>AWS Cloud Engineer | DevOps Specialist</p>
                      </header>
                      
                      <section>
                          <h2>Contact Information</h2>
                          <p>Email: samiksha@example.com</p>
                          <p>Phone: (123) 456-7890</p>
                          <p>Location: Cloud City</p>
                      </section>
                      
                      <section>
                          <h2>Skills</h2>
                          <div class="skills">
                              <span>AWS</span>
                              <span>Terraform</span>
                              <span>Docker</span>
                              <span>Linux</span>
                              <span>Networking</span>
                              <span>Security</span>
                              <span>Python</span>
                              <span>CI/CD</span>
                          </div>
                      </section>
                      
                      <section>
                          <h2>Experience</h2>
                          <p><strong>Cloud Engineer</strong> - Current</p>
                          <p>Designing and implementing AWS infrastructure using Infrastructure as Code.</p>
                      </section>
                      
                      <section>
                          <h2>Certifications</h2>
                          <ul>
                              <li>AWS Certified Solutions Architect</li>
                              <li>Terraform Associate</li>
                              <li>CompTIA Security+</li>
                          </ul>
                      </section>
                      
                      <section>
                          <h2>About This Website</h2>
                          <p>This resume website is hosted on AWS infrastructure:</p>
                          <ul>
                              <li>EC2 Instance (t2.micro - Free Tier)</li>
                              <li>Nginx Web Server</li>
                              <li>Security Group configured for HTTP access</li>
                              <li>Deployed using Terraform Infrastructure as Code</li>
                          </ul>
                      </section>
                  </div>
              </body>
              </html>
              HTML_EOF
              
              # Set correct permissions
              sudo chmod 644 /usr/share/nginx/html/index.html
              
              # Restart Nginx
              sudo systemctl restart nginx
              EOF

  # Root volume - Free Tier allows up to 30 GB
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    encrypted   = true  # Enable encryption for security
    delete_on_termination = true
  }

  tags = {
    Name = "${local.name_prefix}Resume-Webserver"
  }
}

# 3. Elastic IP for static public IP
resource "aws_eip" "web_eip" {
  domain = "vpc"
  instance = aws_instance.web_server.id
  
  tags = {
    Name = "${local.name_prefix}WebServer-EIP"
  }
}

# Outputs to get the website URL
output "website_url" {
  value = "http://${aws_eip.web_eip.public_ip}"
}

output "public_ip" {
  value = aws_eip.web_eip.public_ip
}

output "instance_id" {
  value = aws_instance.web_server.id
}

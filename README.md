# AWS Infrastructure Project

## Overview
A comprehensive AWS infrastructure deployment demonstrating multi-tier architecture, high availability, and cloud best practices. This project implements a scalable web application infrastructure with proper networking, security, and monitoring.

## Tasks
1. **VPC Setup** - Networking with public/private subnets, IGW, NAT
2. **EC2 Web Hosting** - Static website on Nginx
3. **High Availability** - ALB + Auto Scaling Group
4. **Cost Monitoring** - CloudWatch billing alerts
5. **Architecture Diagram** - Scalable design for 10k users

## Deployment Instructions

### Prerequisites
- AWS Account with Free Tier eligibility
- Terraform v1.0+
- AWS CLI configured
- Git for version control

### Quick Start
```bash
# Clone repository
git clone https://github.com/samikshapatel27/aws-infrastructure-setup.git
cd aws-infrastructure-setup
```

### Deploy specific components
```bash
cd task1-vpc  # Or task2-ec2, task3-ha, etc.
terraform init
terraform plan
terraform apply
```

### Cleanup
```bash
# Destroy infrastructure
terraform destroy

# Verify all resources are terminated
aws ec2 describe-instances --query "Reservations[].Instances[].State.Name"
```

## Key Features
- **Infrastructure as Code**: Fully reproducible deployments
- **High Availability**: Multi-AZ deployment with auto-scaling
- **Security First**: Private subnets, security groups, NACLs
- **Cost Control**: Billing alarms and Free Tier monitoring
- **Scalability**: Architecture designed for 10,000+ concurrent users
- **Observability**: Comprehensive monitoring and logging

## Author
Samiksha Patel

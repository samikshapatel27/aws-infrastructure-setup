# Task 4: Billing & Free Tier Cost Monitoring
# Configuration documentation for cost monitoring setup

provider "aws" {
  region = "us-east-1"
}

# Note: Billing and budget resources have limited Terraform support
# The actual setup was done via AWS Console as shown in screenshots

# This file documents the configuration that was implemented:

# 1. CloudWatch Billing Alarm (configured via Console)
#    - Alarm Name: Monthly-Billing-Alert
#    - Threshold: $1.00 USD (₹100 equivalent)
#    - Metric: AWS/Billing EstimatedCharges
#    - Period: 6 hours
#    - Action: Email notification

# 2. AWS Budget for Free Tier Monitoring (configured via Console)
#    - Budget Name: Free-Tier-Usage-Alert
#    - Budget Amount: $0.10 USD
#    - Alert Threshold: $0.01 USD (alerts on any charge)
#    - Period: Monthly recurring

# 3. Additional Cost Monitoring (configured via Console)
#    - Free Tier dashboard monitoring
#    - Cost Explorer regular review
#    - Billing preferences enabled

# Important: Billing metrics must be enabled in AWS Console first before any billing alarms can be created.

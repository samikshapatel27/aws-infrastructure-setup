# Task 5: AWS Architecture Diagram

## Architecture Explanation
Designed a highly scalable web application architecture capable of handling 10,000 concurrent users. The architecture features CloudFront CDN for global content delivery, AWS WAF for DDoS protection, and Application Load Balancer distributing traffic across an Auto Scaling Group spanning multiple Availability Zones. ElastiCache Redis handles session management and caching, while Aurora PostgreSQL with read replicas ensures database scalability. Security is enforced through Security Groups, NACLs, and VPC flow logs, with CloudWatch providing comprehensive observability.

## Architecture Components
1. **Global Delivery**: CloudFront CDN (Edge Locations)
2. **Security Layer**: AWS WAF + Shield
3. **Load Distribution**: Application Load Balancer
4. **Compute Layer**: Auto Scaling Group with EC2 instances (3+ AZs)
5. **Caching Layer**: ElastiCache Redis Cluster
6. **Database Layer**: Aurora PostgreSQL (Multi-AZ with read replicas)
7. **Storage**: S3 for static assets
8. **Security**: Security Groups, NACLs, VPC Flow Logs
9. **Monitoring**: CloudWatch Metrics, Logs, Alarms
10. **Network**: VPC with Public/Private Subnets, NAT Gateway

## Traffic Flow
1. User → CloudFront → AWS WAF → ALB
2. ALB → Auto Scaling Group → EC2 Instances
3. EC2 → ElastiCache (cache check) → Aurora DB (if cache miss)
4. EC2 → S3 (static assets)
5. All components → CloudWatch (monitoring)

## Files
- `architecture-diagram.png` - Main diagram
- `architecture-diagram.drawio` - Source file
- `architecture-diagram.pdf` - Printable version

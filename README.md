# Terraform VPC
This repository contains Terraform code to provision a highly available and scalable web application infrastructure on Amazon Web Services (AWS). It sets up a Virtual Private Cloud (VPC) with public and private subnets across multiple Availability Zones, an Application Load Balancer (ALB) for traffic distribution, and an Auto Scaling Group (ASG) to manage EC2 instances running a simple web server.
## Table of Contents

* [Architecture Diagram](#architecture-diagram)

* [Features](#features)

* [Prerequisites](#prerequisites)

* [Setup & Deployment](#setup--deployment)

  * [AWS Credentials Configuration](#23aws-credentials-configuration)

  * [Terraform Commands](#terraform-commands)

  * [Accessing the Application](#accessing-the-application)

* [Project Structure](#project-structure)

* [Customization](#customization)

* [Cleanup](#cleanup)

* [Security Considerations](#security-considerations)

* [Troubleshooting](#troubleshooting)

* [Contributing](#contributing)

## Architecture Diagram

The following diagram illustrates the AWS infrastructure provisioned by this Terraform code:

![architecture diagram](https://docs.aws.amazon.com/images/vpc/latest/userguide/images/vpc-example-private-subnets.png)
## Features

This Terraform configuration provisions the following AWS resources:

* **Virtual Private Cloud (VPC):** A logically isolated virtual network (`10.0.0.0/16`).

* **Subnets:**

  * Two **Public Subnets** across two Availability Zones (e.g., `us-east-1a`, `us-east-1b`) for public-facing resources like the ALB and NAT Gateways.

  * Two **Private Subnets** across the same two Availability Zones for your backend EC2 instances, ensuring they are not directly accessible from the internet.

* **Internet Gateway (IGW):** Enables communication between your VPC and the internet for public resources.

* **NAT Gateways:** One in each public subnet, allowing instances in private subnets to initiate outbound internet connections (e.g., for updates, package installations) without being publicly exposed.

* **Route Tables & Associations:** Configured to direct traffic appropriately between public/private subnets and the IGW/NAT Gateways.

* **Security Groups:**

  * One for the **Application Load Balancer (ALB)**, allowing inbound HTTP (port 80) traffic from anywhere.

  * One for the **EC2 instances (web servers)**, allowing inbound HTTP traffic *only* from the ALB's security group, and SSH (port 22) for management (note: restrict SSH in production!).

* **EC2 Launch Template:** Defines the configuration for instances launched by the ASG, including:

  * Latest Amazon Linux 2 AMI.

  * `t2.micro` instance type.

  * User data script to install Apache HTTP Server and serve a simple HTML page. The page content is randomly chosen between two versions, and also displays the instance's Availability Zone.

* **Application Load Balancer (ALB):** Distributes incoming HTTP traffic across the EC2 instances in the ASG.

* **ALB Target Group:** Registers the ASG instances as targets for the ALB and performs health checks.

* **ALB Listener:** Listens for HTTP traffic on port 80 and forwards it to the target group.

* **Auto Scaling Group (ASG):**

  * Manages a desired capacity of EC2 instances (default: 2) distributed across the private subnets.

  * Automatically replaces unhealthy instances.

  * Attaches instances to the ALB target group.

## Prerequisites

Before deploying this infrastructure, ensure you have the following:

* **AWS Account:** An active AWS account with programmatic access.

* **Terraform:** [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) installed (version 1.0.0 or higher recommended).

* **AWS CLI:** [AWS Command Line Interface](https://aws.amazon.com/cli/) installed and configured.

## Setup & Deployment

### AWS Credentials Configuration

Terraform uses the AWS CLI's configured credentials. Ensure your AWS CLI is configured with appropriate permissions to create these resources. You can configure it using:

```
aws configure
```
Provide your AWS Access Key ID, Secret Access Key, default region, and default output format.

### Terraform Commands

1. **Clone this repository:**
```
git clone https://github.com/trishulnaik/Terraform_vpc.git
cd Terraform_vpc
```
2. **Initialize Terraform:**
Navigate to the directory containing your `.tf` files and run:
```
terraform init
```
This command downloads the necessary AWS provider plugin.

3. **Review the plan:**
It's crucial to review the execution plan before applying changes. This command shows you exactly what Terraform will create, modify, or destroy.
```
terraform plan
```
**Important:** Pay close attention to the `+` (create), `~` (modify), and `-` (destroy) symbols.

4. **Apply the configuration:**
If the plan looks correct, apply the changes to your AWS account:
```
terraform apply
```
You will be prompted to type `yes` to confirm the operation.

### Accessing the Application

Once `terraform apply` completes successfully, Terraform will output the DNS name of your Application Load Balancer.

Look for the `alb_dns_name` output in your terminal:

```
Outputs:

alb_dns_name = "http://my-web-app-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com"
```

Copy this DNS name and paste it into your web browser. You should see one of the two static web pages served by your EC2 instances. Refreshing the page may show the other version, demonstrating the load balancing. The page will also display the Availability Zone of the instance serving the request.

## Project Structure
```
Need to update
```
## Customization

You can customize this infrastructure by modifying the `terraform.tfvars` file for customizing the variables mentioned in the `variables.tf` file:

* **AWS Region:** Change `region = "us-east-1"` in the `provider "aws"` block.

* **VPC CIDR:** Adjust `cidr_block = "10.0.0.0/16"` in `aws_vpc.main`.

* **Subnet CIDRs:** Modify `cidr_block` for `aws_subnet.public_a`, `public_b`, `private_a`, `private_b`.

* **Instance Type:** Change `instance_type = "t2.micro"` in `aws_launch_template.asg_launch_template`.

* **ASG Capacity:** Adjust `min_size`, `max_size`, and `desired_capacity` in `aws_autoscaling_group.web_asg`.

* **Web Content:** Modify the `HTML_CONTENT_1` and `HTML_CONTENT_2` variables in the `user_data` script within `aws_launch_template.asg_launch_template` to change the content served by your web servers.

* **Security Group Rules:** Tighten `cidr_blocks` for SSH access in `aws_security_group.web_sg` for production environments.

## Cleanup

To destroy all the AWS resources provisioned by this Terraform code:

1. **Navigate to your project directory:**

```
cd /path/to/your/terraform/project
```
2. **Run Terraform destroy:**

```
terraform destroy
```
Terraform will show you a plan of all resources that will be destroyed. Type `yes` to confirm.

**Warning:** This command will permanently delete all resources created by this configuration in your AWS account. Ensure you understand the implications before proceeding.

## Security Considerations

* **SSH Access:** The current `web_sg` allows SSH (port 22) from `0.0.0.0/0` (anywhere). **This** is highly **insecure for production environments.** You should restrict this to specific IP addresses or ranges (e.g., your office IP, a bastion host's IP).

* **IAM Roles:** For production, consider creating dedicated IAM Roles for your EC2 instances with only the necessary permissions, rather than relying solely on the default instance profile.

* **HTTPS:** For a production web application, you would typically configure the ALB to use HTTPS (port 443) with an SSL/TLS certificate from AWS Certificate Manager (ACM).

* **Least Privilege:** Always apply the principle of least privilege to your security groups and IAM policies.

## Troubleshooting

* **`terraform init` errors:** Check your internet connection and AWS provider configuration.

* `terraform plan`**/`apply` errors:**

* Read the error messages carefully; they often point to the exact issue (e.g., invalid AMI ID, missing permissions, conflicting resource names).

* Ensure your AWS credentials have the necessary permissions.

* Verify resource limits in your AWS account if you encounter capacity errors.

* **Web page not loading:**

* Check the ALB's health checks in the AWS console to see if instances are registered and healthy.

* Verify the security group rules on both the ALB and the EC2 instances.

* Check the EC2 instance system logs or Apache logs for errors.

* Ensure the `user_data` script executed successfully (you can check instance console output or `cloud-init` logs on the EC2 instance).

## Contributing

Feel free to fork this repository, make improvements, and submit pull requests.

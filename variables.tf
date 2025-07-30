variable "vpc_name" {
  type = string
  description = "Name of the VPC"
  default = "test-vpc"
}
variable "region" {
  type = string
  description = "The region where you want to create VPC"
  default = "us-east-1"
}

variable "vpc_cidr" {
  type = string
  description = "CIDR block for the main VPC"
  default = "10.0.0.0/16"
}

variable "instance_type" {
  type = string
  description = "Instance type of the lauch template"
  default = "t2.micro"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for all the subnets"
  type = object({
    public_a = string
    public_b = string
    private_a = string
    private_b = string
  })
  default = {
    public_a = "10.0.1.0/24"
    public_b = "10.0.2.0/24"
    private_a = "10.0.3.0/24"
    private_b = "10.0.4.0/24"
  }
}

variable "asg_capacity" {
    description = "Auto Scaling Group Capacity"
    type = object({
      min_size = number
      max_size = number
      desired_capacity = number
    })
    default = {
      min_size = 2
      max_size = 4
      desired_capacity = 2
    }  
}
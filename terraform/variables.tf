variable "ami_id" {
  description = "Ubuntu Server 24.04 LTS (HVM),EBS General Purpose (SSD) Volume Type for us-west-1"
  default     = "ami-014e30c8a36252ae5"
}

variable "instance_type_micro" {
  default = "t2.micro"
}

variable "instance_type_medium" {
  default = "t2.medium"
}

variable "vpc_id" {
  description = "VPC to deploy instances in"
  default     = "" # Fill after VPC setup
}

variable "subnet_id" {
  description = "Subnet ID for instances"
  default     = "" # Fill after VPC setup
}

variable "aws_access_key_id" {}

variable "aws_secret_key_id" {}

variable "aws_region" {
  description = "The AWS Region where the instance will be launched"
  default     = "us-east-1"
}

variable "docker_registry_instance_private_ip" {
  default = "192.168.0.10"
}

variable "aws_ec2_instance_type" {
  description = "The instance type of the EC2 server"
  default     = "t2.nano"
}

variable "aws_ec2_ami" {
  description = "The Amazon Machine Image from which to launch the EC2 server"
  default     = "ami-80861296"
}

variable "ssh_key_file" {
  description = "path of the ssh private key file"
  default     = "ssh_key/docker_ssh_key"
}

variable "ssh_key_name" {
  default = "docker_ssh_key"
}

variable "docker_vpc_cidr_block" {
  default = "192.168.0.0/16"
}

variable "docker_client_public_subnet_cidr_block" {
  default = "192.168.1.0/24"
}

variable "docker_registry_private_subnet_cidr_block" {
  default = "192.168.0.0/24"
}

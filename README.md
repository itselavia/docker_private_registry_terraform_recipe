# docker_private_registry_terraform_recipe
A simple private Docker registry setup in an AWS VPC with private and public subnets

This Terraform recipe orchestrates a private docker registry in a private subnet and a docker client instance in a public subnet on AWS. The project is set up with VPC layout, security groups, scripts, ssh keys and other sensible defaults (which can be changed by editing the vars.tf file) to automatically bring up the entire infrastructure with single 'terraform apply' command.

Terraform will ask for the values of AWS_ACCESS_KEY and AWS_SECRET_KEY upon execution

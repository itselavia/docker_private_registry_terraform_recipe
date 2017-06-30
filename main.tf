provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_key_id}"
}

resource "aws_key_pair" "ssh-access-key" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}

resource "aws_vpc" "docker_vpc" {
  cidr_block           = "${var.docker_vpc_cidr_block}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "docker_vpc"
  }
}

resource "aws_subnet" "docker_registry_private_subnet" {
  vpc_id                  = "${aws_vpc.docker_vpc.id}"
  map_public_ip_on_launch = true
  cidr_block              = "${var.docker_registry_private_subnet_cidr_block}"

  tags {
    Name = "docker_registry_private_subnet"
  }
}

resource "aws_subnet" "docker_client_public_subnet" {
  vpc_id                  = "${aws_vpc.docker_vpc.id}"
  map_public_ip_on_launch = true
  cidr_block              = "${var.docker_client_public_subnet_cidr_block}"

  tags {
    Name = "docker_client_public_subnet"
  }
}

resource "aws_internet_gateway" "docker_internet_gateway" {
  vpc_id = "${aws_vpc.docker_vpc.id}"

  tags {
    Name = "docker_internet_gateway"
  }
}

resource "aws_route" "internet_access_route" {
  route_table_id         = "${aws_vpc.docker_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.docker_internet_gateway.id}"
}

resource "aws_default_route_table" "docker_default_route_table" {
  default_route_table_id = "${aws_vpc.docker_vpc.default_route_table_id}"

  tags {
    Name = "docker_route_table"
  }
}

resource "aws_eip" "docker_nat_gateway_eip" {
  vpc = true
}

resource "aws_nat_gateway" "docker_nat_gateway" {
  allocation_id = "${aws_eip.docker_nat_gateway_eip.id}"
  subnet_id     = "${aws_subnet.docker_client_public_subnet.id}"

  depends_on = ["aws_internet_gateway.docker_internet_gateway"]
}

resource "aws_route_table" "docker_private_registry_route_table" {
  vpc_id = "${aws_vpc.docker_vpc.id}"

  tags {
    Name = "docker_private_registry_route_table"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = "${aws_route_table.docker_private_registry_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.docker_nat_gateway.id}"
}

resource "aws_route_table_association" "docker_registry_subnet_association" {
  subnet_id      = "${aws_subnet.docker_registry_private_subnet.id}"
  route_table_id = "${aws_route_table.docker_private_registry_route_table.id}"
}

resource "aws_route_table_association" "docker_client_subnet_association" {
  subnet_id      = "${aws_subnet.docker_client_public_subnet.id}"
  route_table_id = "${aws_vpc.docker_vpc.main_route_table_id}"
}

resource "aws_security_group" "docker_client_security_group" {
  name        = "docker_client_security_group"
  description = "allow ssh traffic from outside"
  vpc_id      = "${aws_vpc.docker_vpc.id}"

  ingress {
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

  tags {
    Name = "docker_client_security_group"
  }
}

resource "aws_security_group" "docker_registry_security_group" {
  name        = "docker_registry_security_group"
  description = "allow ssh traffic and port 5000 access only from docker client"
  vpc_id      = "${aws_vpc.docker_vpc.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.docker_client_security_group.id}"]
  }

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = ["${aws_security_group.docker_client_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "docker_registry_security_group"
  }
}

resource "aws_instance" "docker_registry_instance" {
  ami                         = "${var.aws_ec2_ami}"
  instance_type               = "${var.aws_ec2_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.docker_registry_security_group.id}"]
  subnet_id                   = "${aws_subnet.docker_registry_private_subnet.id}"
  associate_public_ip_address = true
  key_name                    = "${var.ssh_key_name}"
  count                       = 1
  private_ip                  = "${var.docker_registry_instance_private_ip}"

  tags {
    Name = "docker_registry_instance"
  }
}

resource "aws_instance" "docker_client_instance" {
  ami                         = "${var.aws_ec2_ami}"
  instance_type               = "${var.aws_ec2_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.docker_client_security_group.id}"]
  subnet_id                   = "${aws_subnet.docker_client_public_subnet.id}"
  associate_public_ip_address = true
  key_name                    = "${var.ssh_key_name}"
  count                       = 1
  depends_on                  = ["aws_instance.docker_registry_instance"]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    agent       = false
    private_key = "${file("${var.ssh_key_file}")}"
  }

  provisioner "file" {
    source      = "bootstrap_scripts/docker_bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "file" {
    source      = "ssh_key/docker_ssh_key"
    destination = "/tmp/docker_ssh_key"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo /tmp/bootstrap.sh ${var.docker_registry_instance_private_ip}",
    ]
  }

  tags {
    Name = "docker_client_instance"
  }
}

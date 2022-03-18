provider "aws" {
  region     = "eu-west-1"
}

resource "aws_key_pair" "aws_keypair" {
  key_name   = "terraform_test"
  public_key = "~/.ssh/id_rsa.pub"
}

resource "aws_vpc" "vpc" {
  cidr_block = "172.16.10.0/24"

  tags = {
    Name = "terraform_vpc"
  }
}

resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "gateway"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terraform_gw.id}"
  }

  tags {
    Name = "Route table"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "${aws_vpc.vpc.cidr_block}"

  # map_public_ip_on_launch = true
  tags = {
    Name = "terraform_subnet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.route_table.id}"
}

resource "aws_security_group" "server_sg" {
  vpc_id = "${aws_vpc.vpc.id}"

  # SSH ingress access for provisioning
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access for provisioning"
  }

  ingress {
    from_port   = "8282"
    to_port     = "8282"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to servers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test_server" {
  ami                         = "ami-08ca3fed11864d6bb"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.server_sg.id}"]
  key_name                    = "${aws_key_pair.aws_keypair.key_name}"
  associate_public_ip_address = true
  count                       = 1

  tags {
    Name = "test_server"
  }

  provisioner "remote-exec" {
    # Install Python for Ansible
    inline = ["sudo apt -y update && sudo apt -y install python ansible"]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = "~/.ssh/id_rsa"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' --private-key ~/.ssh/id_rsa ansible.yml" 
  }
}

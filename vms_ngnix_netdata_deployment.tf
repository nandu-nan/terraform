terraform {
  backend "s3" {
    bucket = "nginxnetdata"
    key    = "nginx/nginx.tfstate"
    region = "us-east-2"
    profile = "dev"
   }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  provider = aws.dev
  owners   = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-hirsute-21.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
	
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
 }

data "aws_ami" "centos" {
  most_recent = true
  provider = aws.dev
  owners   = ["125523088429"]
  filter {
    name   = "name"
    values = ["CentOS 8.3.2011 x86_64*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

 }

resource "aws_key_pair" "deployer" {
  key_name   = "ec2key"
  provider = aws.dev
  public_key = file(var.pubkey)
}

resource "aws_security_group" "ec2_pub_sg" {
  name        = "EC2-Public-SG"
  provider = aws.dev
  description = "Internet reaching access for EC2 instances"
  vpc_id      = var.vpcid	
  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "ec2_priv_sg" {
  name        = "EC2-Private-SG"
  provider = aws.dev
  description = "Only allow nginx instance to connect to netdata"
  vpc_id      = var.vpcid

  ingress {
    from_port       = 19999
    protocol        = "TCP"
    to_port         = 19999
    security_groups = [aws_security_group.ec2_pub_sg.id]
  }

  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "inv" {
  provisioner "local-exec" {
    command = "cat /dev/null > inventory"
  }
}

resource "aws_instance" "backend" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2type
  provider = aws.dev
  vpc_security_group_ids = [aws_security_group.ec2_priv_sg.id]
  key_name = "ec2key"
  tags = {
    Name = "u21.local"
  }
  
  provisioner "local-exec" {
    command = "echo [backend] >> inventory;echo ${aws_instance.backend.public_ip} ansible_user=ubuntu  >> inventory"
  }
}

resource "aws_instance" "frontend" {
  ami           = data.aws_ami.centos.id
  instance_type = var.ec2type
  provider = aws.dev
  vpc_security_group_ids = [aws_security_group.ec2_pub_sg.id]
  key_name = "ec2key"
  tags = {
    Name = "c8.local"
  }
    provisioner "local-exec" {
    command = "echo [frontend] >> inventory;echo ${aws_instance.frontend.public_ip} ansible_user=centos  >> inventory"
  }

    provisioner "local-exec" {
    command = "sleep 120;ansible-playbook  -v -i inventory --private-key=${var.privsshkey} nginx_netdata_deploy.yml -e backendip=${aws_instance.backend.private_ip}"
  }
}

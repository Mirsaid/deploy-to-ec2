provider "aws" {

  region     = "eu-west-3"
  access_key = ""
  secret_key = ""
}


variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "var.public_key_location" {}
variable "var.private_key_location" {}
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cid.block

  tags = {

    Name : "${var.env + prefix}-vpc"

  }

}

resource "aws_subnet" "dev-subnet-1" {

  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = var.subnet_block
  availability_zone = var.avail_zone

  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}

/*
resource "aws_route_table" "myapp-rt" {

vpc_id = aws_vpc.myapp-vpc.id
route {

cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.myapp-igw.id

}

tags = {

Name: "{$var.env_prefix}-rtb"

}

}
*/

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {

    Name : "{$var.env_prefix}-igw"

  }
}

/*
resource "aws_route_table_association" "a-rtb-assoc" {

subnet_id = aws_subnet.myapp-subnet.id
route_table = aws_route_table.myapp-rt.id

}
*/

resource "aws_default_route_table" "main-rt" {

  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id

  }
  tags = {

    Name : "{$var.env_prefix}-main-rt"

  }
}

resource "aws_security_group" "myapp-sg" {

  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]

  }

  ingress {

    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }


  egress {

    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_block      = ["0.0.0.0/0"]
    prefix_list_ids = []

  }

  tags = {

    Name : "${var.env_prefix}-myapp-sg"
  }
}


data "aws_ami" "latest-amazon-linux-image" {

  most_recent = true
  owners      = ["amazon"]
  filter {

    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }



}


output "amazon-ami" {

  value = data.aws_ami.latest-amazon-linux-image.id
}

resource "aws_instance" "myapp-server" {

  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  #key_name = "server-key-pair" 
  subnet_id             = aws_subnet.myapp-subnet.id
  vpc_security_zone_ids = [aws_security_group.myapp-sg.id]
  availability_zone     = var.avail_zone
  tags = {

    Name : "${var.env_prefix}-server"


  }
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name


  user_data = file("entry-script.sh")



 /* connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_location)
  }
  provisioner "remote-exec" {

    inline = {

      script = file("entry-script.sh")
    }

  }
*/



}

resource "aws_key_pair" "ssh-key" {

  key_name   = "server-key"
  public_key = file(var.public_key_location)

}



resource "aws_instance" "myapp-server" {

  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  #key_name = "server-key-pair"
  subnet_id             = var.subnet_id
  vpc_security_zone_ids = [aws_security_group.myapp-sg.id]
  availability_zone     = var.avail_zone
  tags = {

    Name : "${var.env_prefix}-server"


  }
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name


  user_data = file("entry-script.sh")


}

resource "aws_key_pair" "ssh-key" {

  key_name   = "server-key"
  public_key = file(var.public_key_location)

}
data "aws_ami" "latest-amazon-linux-image" {

  most_recent = true
  owners      = ["amazon"]

  filter {

    name   = "name"
    values = [var.image_name]
  }


}

resource "aws_security_group" "myapp-sg" {

  name   = "myapp-sg"
  vpc_id = var.vpc_id

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


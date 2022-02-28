resource "aws_instance" "ami-instance" {
  count = length(var.availability-zones)
  ami           = data.aws_ami.ami.id
  instance_type = "t3.medium"
  availability_zone = var.availability-zones[count.index]
  vpc_security_group_ids = [element(aws_security_group.allow_tls.*.id, count.index)]
  tags = {
    Name = "${var.component}-ami-instance-${var.availability-zones[count.index]}"
  }
}

resource "aws_security_group" "allow_tls" {
  count = length(data.terraform_remote_state.vpc.outputs.PRIVATE_CIDR)
  name        = "Allow SSH for ami-${var.component}-${count.index}"
  description = "Allow SSH for ami -${var.component}-${count.index}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description      = "TCP from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = [element(data.terraform_remote_state.vpc.outputs.PRIVATE_CIDR, count.index)]
  }

  egress {
    description      = "TCP from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = [element(data.terraform_remote_state.vpc.outputs.PRIVATE_CIDR, count.index)]
  }

  tags = {
    Name = "Allow SSH for ami -${var.component}-${count.index}"
  }
}
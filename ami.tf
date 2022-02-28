resource "aws_instance" "ami-instance" {
  count = length(var.availability-zones)
  ami           = data.aws_ami.ami.id
  instance_type = "t3.medium"
  availability_zone = var.availability-zones[count.index]
  vpc_security_group_ids = [element(aws_security_group.allow_tls.*.id, count.index)]
  subnet_id = element(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNET, count.index)
  tags = {
    Name = "${var.component}-ami-instance-${var.availability-zones[count.index]}"
  }
}

resource "null_resource" "apply" {
  count = length(var.availability-zones)
  provisioner "remote-exec" {
    connection {
      host = element(aws_instance.ami-instance.*.public_ip, count.index)
      user = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_PASS"]
    }
    inline = [
      "sudo pip install ansibe",
      "echo localhost component=${var.component} >/tmp/hosts",
      "ansible-pull -i /tmp/hosts -U https://github.com/kesavakadiyala/ansible.git roboshop_project.yml -t ${var.component} -e PAT=${var.PAT}"
    ]
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
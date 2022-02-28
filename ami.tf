resource "aws_instance" "ami-instance" {
  count = length(var.availability-zones)
  ami           = data.aws_ami.ami.id
  instance_type = "t3.medium"
  availability_zone = var.availability-zones[count.index]
  vpc_security_group_ids = [aws_security_group.allow-ssh-for-ami.id]
  subnet_id = element(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNET, count.index)
  tags = {
    Name = "${var.component}-ami-instance-${var.availability-zones[count.index]}"
  }
}

resource "null_resource" "apply" {
  count = length(var.availability-zones)
  provisioner "remote-exec" {
    connection {
      host = element(aws_instance.ami-instance.*.private_ip, count.index)
      user = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_PASS"]
    }
    inline = [
      "yum install python3-pip -y",
      "pip3 install pip --upgrade",
      "pip3 install ansible==4.1.0",
      "echo localhost component=${var.component} >/tmp/hosts",
      "ansible-pull -i /tmp/hosts -U https://github.com/kesavakadiyala/ansible.git roboshop_project.yml -t ${var.component} -e PAT=${var.PAT}"
    ]
  }
}

resource "aws_security_group" "allow-ssh-for-ami" {
  name        = "Allow-SSH-for-ami-${var.component}"
  description = "Allow-SSH-for-ami-${var.component}"
  vpc_id = data.terraform_remote_state.vpc.outputs.VPC_ID
  ingress {
    description = "TLS from VPC"
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

  tags = {
    Name = "Allow-SSH-for-ami-${var.component}"
  }
}
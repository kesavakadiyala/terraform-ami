resource "aws_instance" "ami-instance" {
  ami           = data.aws_ami.ami.id
  instance_type = "t3.medium"
  vpc_security_group_ids = [aws_security_group.allow-ssh-for-ami.id]
  subnet_id = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNET
  tags = {
    Name = "${var.component}-ami-instance"
  }
}

resource "null_resource" "apply" {
  provisioner "remote-exec" {
    connection {
      host = aws_instance.ami-instance.private_ip
      user = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_PASS"]
    }
    inline = [
      "sudo yum install python3-pip -y",
      "sudo pip3 install pip --upgrade",
      "sudo pip3 install ansible==4.1.0",
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

module "files" {
  source  = "matti/resource/shell"
  command = "date +%s"
}

resource "aws_ami_from_instance" "ami" {
  name               = "${var.component}-${module.files.stdout}"
  source_instance_id = aws_instance.ami-instance.id
}
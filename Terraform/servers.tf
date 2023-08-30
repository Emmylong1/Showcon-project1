#Bastion
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = "true"
  security_groups             = [aws_security_group.allow_ssh.id]
  key_name                    = aws_key_pair.k8_ssh.key_name
  ##https://github.com/hashicorp/terraform/issues/30134
  user_data = <<-EOF
                #!bin/bash
                echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> /etc/ssh/sshd_config.d/10-insecure-rsa-keysig.conf
                systemctl reload sshd
                echo "${tls_private_key.ssh.private_key_pem}" >> /home/ubuntu/.ssh/id_rsa
                chown ubuntu /home/ubuntu/.ssh/id_rsa
                chgrp ubuntu /home/ubuntu/.ssh/id_rsa
                chmod 600   /home/ubuntu/.ssh/id_rsa
                echo "starting ansible install"
                apt-add-repository ppa:ansible/ansible -y
                apt update
                apt install ansible -y
                EOF

  tags = {
    Name = "Bastion"
  }
}

#Master
resource "aws_instance" "masters" {
  count           = var.master_node_count
  ami             = var.ami_id
  instance_type   = var.master_instance_type
  subnet_id       = element(module.vpc.private_subnets, count.index)
  key_name        = aws_key_pair.k8_ssh.key_name
  security_groups = [aws_security_group.k8_nondes.id, aws_security_group.k8_masters.id]

  tags = {
    Name = format("Master-%02d", count.index + 1)
  }
}

#Worker
resource "aws_instance" "workers" {
  count           = var.worker_node_count
  ami             = var.ami_id
  instance_type   = var.worker_instance_type
  subnet_id       = element(module.vpc.private_subnets, count.index)
  key_name        = aws_key_pair.k8_ssh.key_name
  security_groups = [aws_security_group.k8_nondes.id, aws_security_group.k8_workers.id]

  user_data = <<-EOF
    #!/bin/bash
    #!/bin/bash
    export DB_USERNAME=${var.db_username}
    export DB_PASSWORD=${var.db_password}
  EOF

  tags = {
    Name = format("Worker-%02d", count.index + 1)
  }
}



resource "aws_db_instance" "mydb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "aws_db_parameter_group.custom_parameters_group"
  skip_final_snapshot  = true
  multi_az             = true

  vpc_security_group_ids = [
    aws_security_group.allow_rds.id,
    # Add any additional security groups here if needed
  ]

  db_subnet_group_name = aws_db_subnet_group.mydb_subnet_group.name # Use db_subnet_group_name here

  tags = {
    Name = "MyDBInstance"
  }
}


resource "aws_db_subnet_group" "mydb_subnet_group" {
  name       = "mydb-subnet-group"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
}


/*# Grant the Bastion host and worker nodes access to the RDS instance
resource "aws_security_group_rule" "allow_db_from_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.allow_rds.id
  source_security_group_id = aws_security_group.allow_ssh.id
}

resource "aws_security_group_rule" "allow_db_from_workers" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.allow_rds.id
  source_security_group_id = aws_security_group.k8_workers.id
}
*/
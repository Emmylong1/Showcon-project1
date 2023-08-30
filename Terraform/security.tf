resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "k8_nondes" {
  name        = "k8_nodes"
  description = "sec group for k8 nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "k8_masters" {
  name        = "k8_masters"
  description = "sec group for k8 master nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    #Kubernetes API server
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    #etcd server client API
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    #Kubelet API
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    #kube-scheduler
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    #kube-controller-manager
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

}

resource "aws_security_group" "k8_workers" {
  name        = "k8_workers"
  description = "sec group for k8 worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    #Kubelet API
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    #NodePort Services†
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
}

resource "aws_security_group" "allow_rds" {
  name        = "allow_rds"
  description = "Security group for RDS instance"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules (inbound traffic)
  # Allow traffic from Bastion host
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh.id]
  }

  # Allow traffic from Worker nodes
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.k8_workers.id]
  }

  # Egress rules (outbound traffic)
  # Allow traffic to Bastion host
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh.id]
  }

  # Allow traffic to Worker nodes
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.k8_workers.id]
  }

  # Allow traffic to Master nodes
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.k8_masters.id]
  }
}

# Grant the Bastion host and worker nodes access to the RDS instance
resource "aws_security_group_rule" "allow_db_from_workers" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.allow_rds.id
  source_security_group_id = aws_security_group.k8_workers.id
}
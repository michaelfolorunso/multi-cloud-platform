# EKS cluster security group — controls access to the control plane
# only our VPC can talk to it, nothing from the internet
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg-${var.environment}"
  description = "Security group for EKS control plane"
  vpc_id      = aws_vpc.nexcloud_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kubectl access from within VPC only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all outbound"
  }

  tags = {
    Name        = "${var.project_name}-eks-cluster-sg-${var.environment}"
    Environment = var.environment
  }
}

# EKS node security group — worker nodes talk to each other through this
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-sg-${var.environment}"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.nexcloud_vpc.id

  # nodes need to talk to each other freely — pods communicate across nodes
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
    description = "nodes talking to each other"
  }

  # control plane needs to reach nodes for health checks
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "control plane to node communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "nodes need internet to pull container images"
  }

  tags = {
    Name        = "${var.project_name}-eks-nodes-sg-${var.environment}"
    Environment = var.environment
  }
}

# RDS security group — only EKS nodes can hit the database
# port 5432 is postgres, nothing else opens
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.nexcloud_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "postgres access from EKS nodes only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg-${var.environment}"
    Environment = var.environment
  }
}
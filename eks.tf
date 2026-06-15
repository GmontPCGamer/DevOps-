# Clúster EKS enlazado a la VPC definida en main.tf

resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-sg-eks"
  description = "SG para nodos y control plane EKS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Trafico interno del cluster"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "HTTPS API server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-eks"
  })
}

resource "aws_eks_cluster" "innovatech" {
  name     = "innovatech-cluster"
  role_arn = data.aws_iam_role.lab_role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids              = [aws_subnet.public_frontend.id, aws_subnet.public_eks.id]
    security_group_ids      = [aws_security_group.eks_nodes.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  tags = merge(local.common_tags, {
    Name     = "${var.project_name}-eks-cluster"
    Proyecto = "innovatech-chile"
  })
}

resource "aws_eks_node_group" "innovatech_nodes" {
  cluster_name    = aws_eks_cluster.innovatech.name
  node_group_name = "innovatech-nodes"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = [aws_subnet.public_frontend.id, aws_subnet.public_eks.id]
  instance_types  = ["t3.medium"]
  version         = "1.32"

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-nodes"
  })

  depends_on = [aws_eks_cluster.innovatech]
}

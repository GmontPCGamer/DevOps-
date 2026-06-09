# ── eks.tf ────────────────────────────────────────────────────────────────────
# Crea el clúster EKS de Innovatech Chile.

# ── Red existente (se busca dinámicamente, sin IDs fijos) ─────────────────────
data "aws_vpc" "existing" {
  default = true   # usa la VPC por defecto de la cuenta, que siempre existe en Academy
}

data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "availabilityZone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

data "aws_security_group" "eks_sg" {
  filter {
    name   = "group-name"
    values = ["default"]   # SG por defecto que siempre existe en la VPC
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

# ── Clúster EKS ───────────────────────────────────────────────────────────────
resource "aws_eks_cluster" "innovatech" {
  name     = "innovatech-cluster"
  role_arn = data.aws_iam_role.lab_role.arn   # LabRole, no se crea uno nuevo

  # Red: subredes donde vivirán los nodos del clúster
  vpc_config {
    subnet_ids              = data.aws_subnets.available.ids
    security_group_ids = [data.aws_security_group.eks_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  # Versión de Kubernetes (estable y soportada por EKS en 2025)
  version = "1.32"

  tags = {
    Proyecto = "innovatech-chile"
    Env      = "produccion"
  }
}

# ── Node Group (instancias EC2 que ejecutan los Pods) ─────────────────────────
resource "aws_eks_node_group" "innovatech_nodes" {
  cluster_name    = aws_eks_cluster.innovatech.name
  node_group_name = "innovatech-nodes"
  node_role_arn   = data.aws_iam_role.lab_role.arn   # mismo LabRole

  subnet_ids = data.aws_subnets.available.ids

  # Tipo de instancia: t3.medium es suficiente para académico y es económico
  instance_types = ["t3.medium"]
  version         = "1.32"

  # Escalado automático del grupo de nodos:
  #   desired = nodos al inicio
  #   min     = mínimo para alta disponibilidad (2 nodos en distinta AZ)
  #   max     = techo para no exceder créditos de AWS Academy
  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  # Actualización sin downtime: reemplaza un nodo a la vez
  update_config {
    max_unavailable = 1
  }

  tags = {
    Proyecto = "innovatech-chile"
    Env      = "produccion"
  }

  # El clúster debe existir antes que el node group
  depends_on = [aws_eks_cluster.innovatech]
}

# ── Outputs útiles ─────────────────────────────────────────────────────────────
output "eks_cluster_name" {
  description = "Nombre del clúster EKS"
  value       = aws_eks_cluster.innovatech.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint del API server de Kubernetes"
  value       = aws_eks_cluster.innovatech.endpoint
}

output "eks_kubeconfig_command" {
  description = "Comando para configurar kubectl localmente"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.innovatech.name} --region ${var.aws_region}"
}

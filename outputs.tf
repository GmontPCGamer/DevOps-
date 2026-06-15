output "vpc_id" {
  description = "ID de la VPC principal."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID de la subred publica de frontend."
  value       = aws_subnet.public_frontend.id
}

output "public_eks_subnet_id" {
  description = "ID de la subred publica de EKS (segunda AZ)."
  value       = aws_subnet.public_eks.id
}

output "private_subnet_id" {
  description = "ID de la subred privada de backend/data."
  value       = aws_subnet.private_backend_data.id
}

output "frontend_public_ip" {
  description = "Direccion IP publica de la instancia EC2 frontend."
  value       = aws_instance.frontend.public_ip
}

output "backend_private_ip" {
  description = "Direccion IP privada de la instancia EC2 backend."
  value       = aws_instance.backend.private_ip
}

output "data_private_ip" {
  description = "Direccion IP privada de la instancia EC2 data."
  value       = aws_instance.data.private_ip
}

output "security_group_ids" {
  description = "Grupos de seguridad por cada capa."
  value = {
    front = aws_security_group.sg_front.id
    back  = aws_security_group.sg_back.id
    data  = aws_security_group.sg_data.id
    eks   = aws_security_group.eks_nodes.id
  }
}

output "eks_cluster_name" {
  description = "Nombre del cluster EKS."
  value       = aws_eks_cluster.innovatech.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint del API server de Kubernetes."
  value       = aws_eks_cluster.innovatech.endpoint
}

output "eks_kubeconfig_command" {
  description = "Comando para configurar kubectl localmente."
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.innovatech.name} --region ${var.aws_region}"
}

output "ecr_frontend_url" {
  description = "URL del repositorio ECR para el frontend."
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_back_ventas_url" {
  description = "URL del repositorio ECR para back-ventas."
  value       = aws_ecr_repository.back_ventas.repository_url
}

output "ecr_back_despachos_url" {
  description = "URL del repositorio ECR para back-despachos."
  value       = aws_ecr_repository.back_despachos.repository_url
}

output "ecr_api_node_url" {
  description = "URL del repositorio ECR para api-node."
  value       = aws_ecr_repository.api_node.repository_url
}

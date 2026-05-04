output "vpc_id" {
  description = "ID de la VPC principal."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID de la subred publica de frontend."
  value       = aws_subnet.public_frontend.id
}

output "private_subnet_id" {
  description = "ID de la subred privada de backend/data."
  value       = aws_subnet.private_backend_data.id
}

output "ecr_frontend_url" {
  description = "URL del repositorio ECR frontend en MiniStack."
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_url" {
  description = "URL del repositorio ECR backend en MiniStack."
  value       = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_frontend" {
  description = "Nombre del servicio ECS frontend."
  value       = aws_ecs_service.frontend.name
}

output "ecs_service_backend" {
  description = "Nombre del servicio ECS backend."
  value       = aws_ecs_service.backend.name
}

output "security_group_ids" {
  description = "Grupos de seguridad por cada capa."
  value = {
    front = aws_security_group.sg_front.id
    back  = aws_security_group.sg_back.id
    data  = aws_security_group.sg_data.id
  }
}

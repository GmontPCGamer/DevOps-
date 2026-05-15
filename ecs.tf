# ------------------------------------------------------------
# Cluster ECS
# ------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cluster"
  })
}

# ------------------------------------------------------------
# Task Definition — Frontend (React + Nginx, puerto 80)
# ------------------------------------------------------------
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-td-frontend"
  })
}

# ------------------------------------------------------------
# Task Definition — Backend Ventas (Spring Boot, puerto 8080)
# ------------------------------------------------------------
resource "aws_ecs_task_definition" "back_ventas" {
  family                   = "${var.project_name}-back-ventas"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "back-ventas"
      image     = "${aws_ecr_repository.back_ventas.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:mysql://${aws_instance.data.private_ip}:3306/innovatech_db?useSSL=false&serverTimezone=UTC&createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true"
        },
        { name = "DB_USERNAME", value = "innovatech" },
        { name = "DB_PORT",     value = "3306" },
        { name = "DB_NAME",     value = "innovatech_db" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.back_ventas.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "back-ventas"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-td-back-ventas"
  })
}

# ------------------------------------------------------------
# Task Definition — Backend Despachos (Spring Boot, puerto 8081)
# ------------------------------------------------------------
resource "aws_ecs_task_definition" "back_despachos" {
  family                   = "${var.project_name}-back-despachos"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "back-despachos"
      image     = "${aws_ecr_repository.back_despachos.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:mysql://${aws_instance.data.private_ip}:3306/innovatech_db?useSSL=false&serverTimezone=UTC&createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true"
        },
        { name = "DB_USERNAME", value = "innovatech" },
        { name = "DB_PORT",     value = "3306" },
        { name = "DB_NAME",     value = "innovatech_db" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.back_despachos.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "back-despachos"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-td-back-despachos"
  })
}

# ------------------------------------------------------------
# Service ECS — Frontend (subred pública)
# ------------------------------------------------------------
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-svc-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = [aws_subnet.public_frontend.id]
    security_groups = [aws_security_group.sg_front.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-svc-frontend"
  })
}

# ------------------------------------------------------------
# Service ECS — Backend Ventas (subred privada)
# ------------------------------------------------------------
resource "aws_ecs_service" "back_ventas" {
  name            = "${var.project_name}-svc-back-ventas"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.back_ventas.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = [aws_subnet.private_backend_data.id]
    security_groups = [aws_security_group.sg_back.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-svc-back-ventas"
  })
}

# ------------------------------------------------------------
# Service ECS — Backend Despachos (subred privada)
# ------------------------------------------------------------
resource "aws_ecs_service" "back_despachos" {
  name            = "${var.project_name}-svc-back-despachos"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.back_despachos.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = [aws_subnet.private_backend_data.id]
    security_groups = [aws_security_group.sg_back.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-svc-back-despachos"
  })
}

# ------------------------------------------------------------
# Outputs — URLs de ECR y nombre del cluster
# (usados luego en el workflow de GitHub Actions)
# ------------------------------------------------------------
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

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS."
  value       = aws_ecs_cluster.main.name
}

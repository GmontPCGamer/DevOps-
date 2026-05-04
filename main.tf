terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  endpoints {
    ecr = "http://localhost:4566"
    ecs = "http://localhost:4566"
    ec2 = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  common_tags = merge(
    {
      Proyecto    = "DevOps-"
      Ambiente    = var.environment
      Owner       = "Emilio Hormazabal"
      ManagedBy   = "Terraform"
    },
    var.extra_tags
  )

  az_name = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]

  use_instance_profile       = false
  instance_profile_arn_value = null
  instance_profile_name      = null
}

# ----------------------------------------------------
# Red
# ----------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public_frontend" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = local.az_name
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-frontend"
    Tier = "frontend"
  })
}

resource "aws_subnet" "private_backend_data" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = local.az_name
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-backend-data"
    Tier = "backend-data"
  })
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_frontend.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nat"
  })

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_frontend.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-rt"
  })
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_backend_data.id
  route_table_id = aws_route_table.private_rt.id
}

# ----------------------------------------------------
# Grupos de seguridad
# ----------------------------------------------------
resource "aws_security_group" "sg_front" {
  name        = "${var.project_name}-sg-front"
  description = "SG Frontend: HTTP publico y SSH restringido"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS desde internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH restringido"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-front"
  })
}

resource "aws_security_group" "sg_back" {
  name        = "${var.project_name}-sg-back"
  description = "SG Backend: solo desde SG Frontend"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Trafico de aplicacion desde frontend puerto 8080"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_front.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-back"
  })
}

resource "aws_security_group" "sg_data" {
  name        = "${var.project_name}-sg-data"
  description = "SG Data: acceso a BD solo desde SG Backend"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Base de datos desde backend"
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_back.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-data"
  })
}

# ----------------------------------------------------
# ECR Repositories
# ----------------------------------------------------
resource "aws_ecr_repository" "frontend" {
  name         = "${var.project_name}-frontend"
  force_delete = var.ecr_force_delete

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-frontend"
  })
}

resource "aws_ecr_repository" "backend" {
  name         = "${var.project_name}-backend"
  force_delete = var.ecr_force_delete

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-backend"
  })
}

# ----------------------------------------------------
# ECS Cluster
# ----------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecs-cluster"
  })
}

# ----------------------------------------------------
# ECS Task Definitions
# ----------------------------------------------------
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = "arn:aws:iam::000000000000:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::000000000000:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port_frontend
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-task-frontend"
  })
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = "arn:aws:iam::000000000000:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::000000000000:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port_backend
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-task-backend"
  })
}

# ----------------------------------------------------
# ECS Services
# ----------------------------------------------------
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_frontend.id]
    security_groups  = [aws_security_group.sg_front.id]
    assign_public_ip = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-service-frontend"
  })
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_backend_data.id]
    security_groups  = [aws_security_group.sg_back.id]
    assign_public_ip = false
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-service-backend"
  })
}
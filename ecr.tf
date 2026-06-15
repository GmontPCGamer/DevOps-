resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-frontend"
  })
}

resource "aws_ecr_repository" "back_ventas" {
  name                 = "${var.project_name}-back-ventas"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-back-ventas"
  })
}

resource "aws_ecr_repository" "back_despachos" {
  name                 = "${var.project_name}-back-despachos"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-back-despachos"
  })
}

resource "aws_ecr_repository" "api_node" {
  name                 = "${var.project_name}-api-node"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-api-node"
  })
}

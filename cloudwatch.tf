resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}/frontend"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-logs-frontend"
  })
}

resource "aws_cloudwatch_log_group" "back_ventas" {
  name              = "/ecs/${var.project_name}/back-ventas"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-logs-back-ventas"
  })
}

resource "aws_cloudwatch_log_group" "back_despachos" {
  name              = "/ecs/${var.project_name}/back-despachos"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-logs-back-despachos"
  })
}

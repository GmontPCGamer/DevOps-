resource "aws_cloudwatch_log_group" "eks_apps" {
  name              = "/eks/${var.project_name}/applications"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-logs-eks"
  })
}

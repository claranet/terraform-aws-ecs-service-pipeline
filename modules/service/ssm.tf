resource "aws_ssm_parameter" "image" {
  name  = "/${var.stack_name}/image"
  type  = "String"
  value = "-"

  lifecycle {
    ignore_changes = [value]
  }
}

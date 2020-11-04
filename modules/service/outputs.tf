output "pipeline_target" {
  description = "Information required by a pipeline to deploy to this ECS service."
  value = {
    assume_role = {
      arn = aws_iam_role.pipeline.arn
    }
    auto_deploy = var.pipeline_auto_deploy
    cfn_role = {
      arn = aws_iam_role.cloudformation.arn
    }
    cfn_stack = {
      name   = aws_cloudformation_stack.this.name
      params = aws_cloudformation_stack.this.parameters
    }
    execution_role = {
      arn = aws_iam_role.ecs_execution.arn
    }
    image_parameter = {
      arn  = aws_ssm_parameter.image.arn
      name = aws_ssm_parameter.image.name
    }
    name = var.pipeline_target_name
  }
}

output "service_arn" {
  description = "The ECS service ARN."
  value       = lookup(aws_cloudformation_stack.this.outputs, "ServiceArn", "")
}

output "service_name" {
  description = "The ECS service name."
  value       = lookup(aws_cloudformation_stack.this.outputs, "ServiceName", "")
}

output "task_role_arn" {
  description = "The ECS task role ARN."
  value       = aws_iam_role.ecs_task.arn
}

output "task_role_name" {
  description = "The ECS task role name."
  value       = aws_iam_role.ecs_task.id
}

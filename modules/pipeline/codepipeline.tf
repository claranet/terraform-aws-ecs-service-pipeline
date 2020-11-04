resource "aws_codepipeline" "this" {
  name     = var.name
  role_arn = local.codepipeline_role_arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline.bucket
    encryption_key {
      id   = var.kms_key_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "ECR"
      output_artifacts = ["source"]

      category = "Source"
      owner    = "AWS"
      provider = "ECR"
      version  = "1"

      configuration = {
        ImageTag       = var.source_location.image_tag
        RepositoryName = var.source_location.repository_name
      }
    }
  }

  dynamic "stage" {
    for_each = var.targets
    iterator = each

    content {
      name = each.value.name

      # Approval step.
      # This is skipped when the target has "auto deploy" enabled.
      dynamic "action" {
        for_each = toset(range(each.value.auto_deploy ? 0 : 1))
        content {
          name      = "Approve"
          run_order = "1"

          category = "Approval"
          owner    = "AWS"
          provider = "Manual"
          version  = "1"

          configuration = {
            CustomData = "Approve deployment to ${each.value.name}"
          }
        }
      }

      # Prepare deployment step.
      # Downloads the CFN stack template and writes it to the S3 output
      # artifact location, used by the subsequent CFN stack update action.
      # Downloads the ECR input artifact, extracts the new image from it,
      # and then updates the SSM parameter used by the CFN stack template.
      action {
        name             = "Prepare"
        run_order        = "2"
        input_artifacts  = ["source"]
        output_artifacts = ["${each.value.name}_cloudformation_template"]

        category = "Invoke"
        owner    = "AWS"
        provider = "Lambda"
        version  = "1"

        configuration = {
          FunctionName = module.prepare_deployment_lambda.function_name
          UserParameters = jsonencode({
            AssumeRoleArn      = each.value.assume_role.arn
            ImageParameterName = each.value.image_parameter.name
            StackName          = each.value.cfn_stack.name
            TemplateFilename   = "cfn.yaml"
          })
        }
      }

      # Cloudformation stack update step.
      # Uses the output artifact from the Lambda function which contains
      # the CFN template. The CFN template parameters use SSM parameters,
      # which get updated by Lambda in the previous action.
      action {
        name            = "Deploy"
        run_order       = "3"
        input_artifacts = ["${each.value.name}_cloudformation_template"]

        category = "Deploy"
        owner    = "AWS"
        provider = "CloudFormation"
        version  = "1"

        configuration = {
          ActionMode         = "CREATE_UPDATE"
          RoleArn            = each.value.cfn_role.arn
          StackName          = each.value.cfn_stack.name
          TemplatePath       = "${each.value.name}_cloudformation_template::cfn.yaml"
          ParameterOverrides = jsonencode(each.value.cfn_stack.params)
        }

        role_arn = each.value.assume_role.arn
      }
    }
  }
}

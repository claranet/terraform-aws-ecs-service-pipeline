variable "name" {
  description = "The name of the pipeline to create."
  type        = string
}

variable "kms_key_arn" {
  description = "The KMS key to use for artifacts."
  type        = string
}

variable "source_location" {
  description = "The pipeline ECR source location. The pipeline will start when an image is pushed here."
  type        = object({ image_tag = string, repository_arn = string, repository_name = string })
}

variable "targets" {
  description = "A list of targets to deploy to. This should be a list of 'pipeline_target' outputs from uses of the 'asg' module."
  type = list(object({
    assume_role = object({
      arn = string
    })
    auto_deploy = bool
    cfn_role = object({
      arn = string
    })
    cfn_stack = object({
      name   = string
      params = map(string)
    })
    execution_role = object({
      arn = string
    })
    image_parameter = object({
      arn  = string
      name = string
    })
    name = string
  }))
}

variable "repo_name" {
  description = "The name of the ECR repository to create."
  type        = string
}

variable "extra_repo_names" {
  description = "The names of any additional ECR repositories to create."
  type        = list(string)
  default     = []
}

variable "user_name" {
  description = "The name of the IAM user to create. If not provided, the repo_name will be used."
  type        = string
  default     = ""
}

variable "pipeline_targets" {
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


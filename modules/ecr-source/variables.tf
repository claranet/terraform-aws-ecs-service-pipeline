variable "extra_repo_names" {
  type    = list(string)
  default = []
}

variable "repo_name" {
  type = string
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

variable "user_name" {
  type    = string
  default = ""
}

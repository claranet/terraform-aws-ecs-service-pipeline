variable "assign_public_ip" {
  type    = bool
  default = false
}

variable "autoscaling_max" {
  type    = number
  default = 1
}

variable "autoscaling_min" {
  type    = number
  default = 1
}

variable "autoscaling_target_cpu" {
  type    = number
  default = 80
}

variable "bind_mounts" {
  type    = list(object({ container_path = string, host_path = string, volume_name = string }))
  default = []
}

variable "capacity_provider" {
  type    = string
  default = null
}

variable "capacity_provider_strategy" {
  type    = list(object({ base = number, capacity_provider = string, weight = number }))
  default = []
}

variable "cluster_name" {
  type = string
}

variable "container_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "cpu" {
  type = number
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "gpu" {
  type    = number
  default = 0
}

variable "launch_type" {
  type        = string
  description = "FARGATE or EC2"
}

variable "log_group_name" {
  type = string
}

variable "memory" {
  type = number
}

variable "mount_points" {
  type    = list(map(any))
  default = []
}

variable "pipeline_aws_account_id" {
  description = "The AWS account containing the pipeline."
  type        = string
  default     = null
}

variable "pipeline_auto_deploy" {
  description = "Whether the pipeline should automatically deploy to this ECS service (true) or wait for approval first (false)."
  type        = bool
  default     = null
}

variable "pipeline_target_name" {
  description = "The name to use in the pipeline to describe this ECS service, e.g. 'staging'."
  type        = string
  default     = null
}

variable "secrets" {
  type    = map(string)
  default = {}
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "service_name" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "target_group_arn" {
  type    = string
  default = null
}

variable "volumes" {
  type    = list(map(any))
  default = []
}

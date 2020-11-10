variable "alarm" {
  description = "Configures a CloudWatch alarm for when tasks are not running."
  type = object({
    period              = number
    evaluation_periods  = number
    datapoints_to_alarm = number
    alarm_actions       = list(string)
    ok_actions          = list(string)
  })
  default = null
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI (FARGATE launch type only)."
  type        = bool
  default     = false
}

variable "autoscaling_max" {
  description = "The maximum number of tasks to run."
  type        = number
  default     = 1
}

variable "autoscaling_min" {
  description = "The minimum number of tasks to run."
  type        = number
  default     = 1
}

variable "autoscaling_target_cpu" {
  description = "The average CPU percentage that auto scaling should aim for (if autoscaling_min and autoscaling_max are different)."
  type        = number
  default     = 80
}

variable "bind_mounts" {
  description = "Bind mounts for the container."
  type        = list(object({ container_path = string, host_path = string, volume_name = string }))
  default     = []
}

variable "capacity_provider" {
  description = "The name of a single capacity provider to use (conflicts with capacity_provider_strategy)."
  type        = string
  default     = null
}

variable "capacity_provider_strategy" {
  description = "A list of capacity provider strategy items to use for the service (conflicts with capacity_provider)."
  type        = list(object({ base = number, capacity_provider = string, weight = number }))
  default     = []
}

variable "cluster_name" {
  description = "The ECS cluster to create this service on."
  type        = string
}

variable "container_name" {
  description = "The name to use for the container in this service."
  type        = string
}

variable "container_port" {
  description = "The port that the container listens on."
  type        = number
}

variable "cpu" {
  description = "The number of cpu units used by the task."
  type        = number
}

variable "environment" {
  description = "A map of environment variables to pass into the container."
  type        = map(string)
  default     = {}
}

variable "gpu" {
  description = "The number of GPUs used by the task."
  type        = number
  default     = 0
}

variable "launch_type" {
  description = "The launch type on which to run your service (FARGATE or EC2)."
  type        = string
}

variable "log_group_name" {
  description = "The name of the log group to use."
  type        = string
}

variable "memory" {
  description = "The amount (in MiB) of memory used by the task."
  type        = number
}

variable "mount_points" {
  description = "Mount points matching this specification: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ecs-taskdefinition-containerdefinitions-mountpoints.html"
  type        = list(map(any))
  default     = []
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
  description = "A map of { ENVIRONMENT_VARIABLE_NAME = secret_or_ssm_parameter_arn } to pass into the container."
  type        = map(string)
  default     = {}
}

variable "security_group_ids" {
  description = "The security groups associated with the task or service. If you do not specify a security group, the default security group for the VPC is used."
  type        = list(string)
  default     = []
}

variable "service_name" {
  description = "The name of the service to create."
  type        = string
}

variable "stack_name" {
  description = "The name of the CloudFormation stack to create."
  type        = string
}

variable "subnet_ids" {
  description = "The subnets associated with the task or service."
  type        = list(string)
  default     = []
}

variable "target_group_arn" {
  description = "The ARN of the Load Balancer target group to associate with the service."
  type        = string
  default     = null
}

variable "volumes" {
  description = "Volumes matching this specification: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ecs-taskdefinition-volumes.html"
  type        = list(map(any))
  default     = []
}

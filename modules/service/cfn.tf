locals {
  # Capacity providers
  capacity_provider_strategy_items = var.capacity_provider != null ? [{ base = null, capacity_provider = var.capacity_provider, weight = 100 }] : var.capacity_provider_strategy
  capacity_provider_strategy = [
    for item in local.capacity_provider_strategy_items :
    merge({ CapacityProvider = item.capacity_provider, Weight = item.weight }, item.base == null ? {} : { Base = item.base })
  ]

  # Environment variables
  environment = [
    for key, value in var.environment :
    { Name = key, Value = value }
  ]

  # GPU
  launch_type              = var.gpu == 0 ? var.launch_type : null
  requires_compatibilities = var.gpu == 0 ? [var.launch_type] : ["EC2"]
  resource_requirements    = var.gpu == 0 ? [] : [{ Type = "GPU", Value = var.gpu }]

  # Network
  assign_public_ip = var.assign_public_ip ? "ENABLED" : "DISABLED"
  load_balancers   = var.target_group_arn == null ? [] : [{ ContainerName = var.container_name, ContainerPort = var.container_port, TargetGroupArn = var.target_group_arn }]

  # Secrets
  secrets = [
    for key, value in var.secrets :
    { Name = key, ValueFrom = value }
  ]

  # Volumes
  bind_mount_points = [
    for item in var.bind_mounts :
    { ContainerPath = item.container_path, SourceVolume = item.volume_name }
  ]
  bind_mount_volumes = [
    for item in var.bind_mounts :
    { Name = item.volume_name, Host = { SourcePath = item.host_path } }
  ]
  mount_points = concat(var.mount_points, local.bind_mount_points)
  volumes      = concat(var.volumes, local.bind_mount_volumes)

  # CloudFormation
  cfn_template_body = trimspace(templatefile("${path.module}/cfn.yaml.tpl", {
    assign_public_ip           = local.assign_public_ip
    autoscaling_max            = var.autoscaling_max
    autoscaling_min            = var.autoscaling_min
    autoscaling_role_arn       = data.aws_iam_role.autoscaling.arn
    autoscaling_target_cpu     = var.autoscaling_target_cpu
    capacity_provider_strategy = local.capacity_provider_strategy
    cfn_params_lambda_arn      = module.cfn_params_lambda.arn
    cluster_name               = var.cluster_name
    container_name             = var.container_name
    container_port             = var.container_port
    cpu                        = var.cpu
    environment                = local.environment
    execution_role_arn         = aws_iam_role.ecs_execution.arn
    launch_type                = local.launch_type
    load_balancers             = local.load_balancers
    log_group_name             = var.log_group_name
    memory                     = var.memory
    mount_points               = local.mount_points
    requires_compatibilities   = local.requires_compatibilities
    resource_requirements      = local.resource_requirements
    secrets                    = local.secrets
    security_group_ids         = var.security_group_ids
    service_name               = var.service_name
    subnet_ids                 = var.subnet_ids
    task_role_arn              = aws_iam_role.ecs_task.arn
    volumes                    = local.volumes
  }))
}

resource "aws_cloudformation_stack" "this" {
  name          = var.stack_name
  iam_role_arn  = local.cfn_role_arn
  template_body = local.cfn_template_body
  parameters = {
    Image        = aws_ssm_parameter.image.name
    TemplateHash = sha256(local.cfn_template_body)
  }
}

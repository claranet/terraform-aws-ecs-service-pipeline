# Note that this file is a Terraform template which generates
# a CloudFormation YAML template. A dollar-brace will be rendered
# by Terraform. A dollar-dollar-brace is escaped by Terraform and
# ends up as a dollar-brace to be parsed by CloudFormation.

Parameters:
  Image:
    Type: AWS::SSM::Parameter::Value<String>
  TemplateHash:
    Type: String

Resources:

  Params:
    Type: Custom::Params
    Properties:
      ClusterName: ${cluster_name}
      Image: !Ref Image
      MaxCapacity: ${autoscaling_max}
      MinCapacity: ${autoscaling_min}
      ServiceName: ${service_name}
      ServiceToken: ${cfn_params_lambda_arn}
      TemplateHash: !Ref TemplateHash

  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      ContainerDefinitions:
      - Environment: ${jsonencode(environment)}
        Essential: true
        Image: !Ref Image
        LogConfiguration:
          LogDriver: awslogs
          Options:
            awslogs-group: ${log_group_name}
            awslogs-region: !Ref AWS::Region
            awslogs-stream-prefix: !GetAtt Params.LOG_STREAM_PREFIX
        MountPoints: ${jsonencode(mount_points)}
        Name: ${container_name}
        PortMappings:
        - ContainerPort: ${container_port}
          HostPort: ${container_port}
          Protocol: tcp
        ResourceRequirements: ${jsonencode(resource_requirements)}
        Secrets: ${jsonencode(secrets)}
      Cpu: ${cpu}
      ExecutionRoleArn: ${execution_role_arn}
      Family: ${container_name}
      Memory: ${memory}
      NetworkMode: awsvpc
      RequiresCompatibilities: ${jsonencode(requires_compatibilities)}
      TaskRoleArn: ${task_role_arn}
      Volumes: ${jsonencode(volumes)}

  Service:
    Type: AWS::ECS::Service
    Properties:
      CapacityProviderStrategy: ${jsonencode(capacity_provider_strategy)}
      Cluster: ${cluster_name}
      DesiredCount: !GetAtt Params.DESIRED_COUNT
%{ if launch_type != null ~}
      LaunchType: ${launch_type}
%{ endif ~}
      LoadBalancers: ${jsonencode(load_balancers)}
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: ${assign_public_ip}
          SecurityGroups: ${jsonencode(security_group_ids)}
          Subnets: ${jsonencode(subnet_ids)}
      TaskDefinition: !Ref TaskDefinition
      ServiceName: ${service_name}

%{ if autoscaling_min != autoscaling_max ~}
  ScalableTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties: 
      MaxCapacity: !GetAtt Params.MAX_CAPACITY
      MinCapacity: !GetAtt Params.MIN_CAPACITY
      ResourceId: !Sub "service/${cluster_name}/$${Service.Name}"
      RoleARN: ${autoscaling_role_arn}
      ScalableDimension: ecs:service:DesiredCount
      ServiceNamespace: ecs

  ScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties: 
      PolicyName: ${service_name}
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref ScalableTarget
      TargetTrackingScalingPolicyConfiguration:
        PredefinedMetricSpecification: 
          PredefinedMetricType: ECSServiceAverageCPUUtilization
        ScaleInCooldown: 0 # no need because there is draining on the load balancer
        ScaleOutCooldown: 60
        TargetValue: ${autoscaling_target_cpu}
%{ endif ~}

Outputs:
  ServiceArn:
    Value: !Ref Service
  ServiceName:
    Value: !GetAtt Service.Name

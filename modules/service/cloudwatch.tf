resource "aws_cloudwatch_metric_alarm" "tasks_below_desired" {
  count = var.autoscaling_min == 0 || var.alarm == null ? 0 : 1

  alarm_name        = "${var.service_name}-tasks-below-desired"
  alarm_description = "This alarm triggers when the ${var.service_name} service in the ${var.cluster_name} ECS cluster has fewer running tasks than the desired count, indicating that tasks may be failing to start."

  metric_query {
    id = "desired"
    metric {
      namespace = "ECS/ContainerInsights"
      dimensions = {
        ClusterName = var.cluster_name
        ServiceName = var.service_name
      }
      metric_name = "DesiredTaskCount"
      period      = var.alarm.period
      stat        = "Minimum"
      unit        = "Count"
    }
  }

  metric_query {
    id = "running"
    metric {
      namespace = "ECS/ContainerInsights"
      dimensions = {
        ClusterName = var.cluster_name
        ServiceName = var.service_name
      }
      metric_name = "RunningTaskCount"
      period      = var.alarm.period
      stat        = "Minimum"
      unit        = "Count"
    }
  }

  metric_query {
    id          = "missing"
    expression  = "IF(desired > running, desired - running, 0)"
    label       = "MissingTaskCount"
    return_data = "true"
  }

  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = var.alarm.evaluation_periods
  datapoints_to_alarm = var.alarm.datapoints_to_alarm

  treat_missing_data = "breaching"

  alarm_actions = var.alarm.alarm_actions
  ok_actions    = var.alarm.ok_actions
}

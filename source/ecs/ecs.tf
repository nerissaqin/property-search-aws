locals {
  lab_role = "arn:aws:iam::679291055404:role/LabRole"
  log_retention_in_days = 30
  name_prefix        = "ecs-fargate-example"
  vpc_id             = "vpc-0f3bacd3df670af1a"
  load_balanced      = true
  task_container_protocol = "HTTP"
  task_container_secrets = null
  task_mount_points = null

  placement_constraints = []
  task_health_check = null
  task_container_command = []
  proxy_configuration = []
  capacity_provider_strategy =[]
  task_stop_timeout = null
  task_host_port = 0
  desired_count = 1
  deployment_controller_type ="ECS"
  service_registry_arn = ""
  propogate_tags ="TASK_DEFINITION"
  platform_version = "LATEST"
  force_new_deployment = false
  wait_for_steady_state = false
  enable_execute_command = true
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent =200
  health_check_grace_period_seconds = null
  task_start_timeout = null
  task_container_environment = {}
  task_container_cpu = null
  ask_container_memory_reservation = null
  task_container_memory_reservation = null
  task_container_memory = null
  task_container_working_directory = ""
  repository_credentials = ""
  container_name = ""
  volume = []
  private_subnet_ids = ["subnet-0d0db60197fe9427a"]

  cluster_id         = aws_ecs_cluster.cluster.id

  task_container_image   = "679291055404.dkr.ecr.us-east-1.amazonaws.com/realestate-admin:4"
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 80
  task_container_assign_public_ip = true

  target_groups = [
    {
      target_group_name = "tg-fargate-example"
      container_port    = 80
    }
  ]

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  tags = {
    Environment = "test"
    Project = "Test"
  }
}

data "aws_region" "current" {}

resource "aws_ecs_cluster" "cluster" {
  name = "example-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }
}


#####
# Cloudwatch
#####
resource "aws_cloudwatch_log_group" "main" {
  name              = local.name_prefix
  retention_in_days = local.log_retention_in_days

  tags       = local.tags
}

#####
# Security groups
#####
resource "aws_security_group" "ecs_service" {
  vpc_id      = local.vpc_id
  name_prefix =  "${local.name_prefix}-ecs-service-sg-"
  description = "Fargate service security group"
  tags = merge(
    local.tags,
    {
      Name =  "${local.name_prefix}-ecs-service-sg"
    },
  )

  revoke_rules_on_delete = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_service" {
  security_group_id = aws_security_group.ecs_service.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "egress_service" {
  security_group_id = aws_security_group.ecs_service.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

#####
# Load Balancer Target group
#####
resource "aws_lb_target_group" "task" {
  for_each = local.load_balanced ? { for tg in local.target_groups : tg.target_group_name => tg } : {}

  name        = lookup(each.value, "target_group_name")
  vpc_id      = local.vpc_id
  protocol    = local.task_container_protocol
  port        = lookup(each.value, "container_port", local.task_container_port)
  target_type = "ip"


  dynamic "health_check" {
    for_each = [local.health_check]
    content {
      enabled             = lookup(health_check.value, "enabled", null)
      interval            = lookup(health_check.value, "interval", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      matcher             = lookup(health_check.value, "matcher", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = lookup(each.value, "target_group_name")
    },
  )
}

#####
# ECS Task/Service
#####
locals {
  task_environment = [
    for k, v in local.task_container_environment : {
      name  = k
      value = v
    }
  ]
}

resource "aws_ecs_task_definition" "task" {
  family                   = local.name_prefix
  execution_role_arn       = local.lab_role
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.task_definition_cpu
  memory                   = local.task_definition_memory
  task_role_arn            = local.lab_role

  container_definitions = <<EOF
[{
  "name": "${local.container_name != "" ? local.container_name : local.name_prefix}",
  "image": "${local.task_container_image}",
  %{if local.repository_credentials != ""~}
  "repositoryCredentials": {
    "credentialsParameter": "${local.repository_credentials}"
  },
  %{~endif}
  "essential": true,
  %{if local.task_container_port != 0 || local.task_host_port != 0~}
  "portMappings": [
    {
      %{if local.task_host_port != 0~}
      "hostPort": ${local.task_host_port},
      %{~endif}
      %{if local.task_container_port != 0~}
      "containerPort": ${local.task_container_port},
      %{~endif}
      "protocol":"tcp"
    }
  ],
  %{~endif}
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${aws_cloudwatch_log_group.main.name}",
      "awslogs-region": "${data.aws_region.current.name}",
      "awslogs-stream-prefix": "container"
    }
  },
  %{if local.task_health_check != null~}
  "healthcheck": {
    "command": ${jsonencode(local.task_health_check.command)},
    "interval": ${local.task_health_check.interval},
    "timeout": ${local.task_health_check.timeout},
    "retries": ${local.task_health_check.retries},
    "startPeriod": ${local.task_health_check.startPeriod}
  },
  %{~endif}
  "command": ${jsonencode(local.task_container_command)},
  %{if local.task_container_working_directory != ""~}
  "workingDirectory": ${local.task_container_working_directory},
  %{~endif}
  %{if local.task_container_memory != null~}
  "memory": ${local.task_container_memory},
  %{~endif}
  %{if local.task_container_memory_reservation != null~}
  "memoryReservation": ${local.task_container_memory_reservation},
  %{~endif}
  %{if local.task_container_cpu != null~}
  "cpu": ${local.task_container_cpu},
  %{~endif}
  %{if local.task_start_timeout != null~}
  "startTimeout": ${local.task_start_timeout},
  %{~endif}
  %{if local.task_stop_timeout != null~}
  "stopTimeout": ${local.task_stop_timeout},
  %{~endif}
  %{if local.task_mount_points != null~}
  "mountPoints": ${jsonencode(local.task_mount_points)},
  %{~endif}
  %{if local.task_container_secrets != null~}
  "secrets": ${jsonencode(local.task_container_secrets)},
  %{~endif}
  "environment": ${jsonencode(local.task_environment)}
}]
EOF

  dynamic "placement_constraints" {
    for_each = local.placement_constraints
    content {
      expression = lookup(placement_constraints.value, "expression", null)
      type       = placement_constraints.value.type
    }
  }

  dynamic "proxy_configuration" {
    for_each = local.proxy_configuration
    content {
      container_name = proxy_configuration.value.container_name
      properties     = lookup(proxy_configuration.value, "properties", null)
      type           = lookup(proxy_configuration.value, "type", null)
    }
  }

  dynamic "volume" {
    for_each = local.volume
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          scope         = lookup(docker_volume_configuration.value, "scope", null)
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", [])
        content {
          file_system_id          = lookup(efs_volume_configuration.value, "file_system_id", null)
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)

          dynamic "authorization_config" {
            for_each = length(lookup(efs_volume_configuration.value, "authorization_config", {})) == 0 ? [] : [lookup(efs_volume_configuration.value, "authorization_config", {})]
            content {
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
              iam             = lookup(authorization_config.value, "iam", null)
            }
          }
        }
      }
    }
  }

  tags = merge(
    local.tags,
    {
      Name = local.container_name != "" ? local.container_name : local.name_prefix
    },
  )
}

resource "aws_ecs_service" "service" {
  name = local.name_prefix

  cluster         = local.cluster_id
  task_definition = aws_ecs_task_definition.task.arn

  desired_count  = local.desired_count
  propagate_tags = local.propogate_tags

  platform_version = local.platform_version
  launch_type      = length(local.capacity_provider_strategy) == 0 ? "FARGATE" : null

  force_new_deployment   = local.force_new_deployment
  wait_for_steady_state  = local.wait_for_steady_state
  enable_execute_command = local.enable_execute_command

  deployment_minimum_healthy_percent = local.deployment_minimum_healthy_percent
  deployment_maximum_percent         = local.deployment_maximum_percent
  health_check_grace_period_seconds  = local.load_balanced ? local.health_check_grace_period_seconds : null

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = local.task_container_assign_public_ip
  }

  dynamic "capacity_provider_strategy" {
    for_each = local.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  /* dynamic "load_balancer" {
    for_each = local.load_balanced ? local.target_groups : []
    content {
      container_name   = local.container_name != "" ? local.container_name : local.name_prefix
      container_port   = lookup(load_balancer.value, "container_port", local.task_container_port)
      target_group_arn = aws_lb_target_group.task[lookup(load_balancer.value, "target_group_name")].arn
    }
  } */

  deployment_controller {
    type = local.deployment_controller_type # CODE_DEPLOY or ECS or EXTERNAL
  }

  dynamic "service_registries" {
    for_each = local.service_registry_arn == "" ? [] : [1]
    content {
      registry_arn   = local.service_registry_arn
      container_name = local.container_name != "" ? local.container_name : local.name_prefix
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-service"
    },
  )
}

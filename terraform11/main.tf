
provider "aws" {
  region = var.region
}

resource "aws_ecs_cluster" "strapi_cluster" {
  name = "task11-strapi-cluster-rutik"
}

resource "aws_cloudwatch_log_group" "rutik_strapi_log_group" {
  name              = "/ecs/rutik-strapi"
  retention_in_days = 7
}


resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task-rutik"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "rutik-strapi"
    image     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/strapi-app-rutik:latest"
    essential = true
    portMappings = [{
      containerPort = 1337
      hostPort      = 1337
      protocol      = "tcp"
    }]
    environment = [
      { name = "DATABASE_CLIENT", value = "sqlite" },
        { name = "APP_KEYS", value = "Rd4EZ4S13CKp1JlAMzxk5A==,R4GDtWxkpBkJuK2Aq4Pv7g==,Q7df6Erx8xr6N6QFwlT4ig==,DUQwEBTNfE5qamNS1y97Xw==" },
        { name = "API_TOKEN_SALT", value = "y6QBwgHTWetn4KoRl7MDTA==" },
        { name = "ADMIN_JWT_SECRET", value = "IbscCljtmC/t/KWWOFYOAg==" }
    ], 
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.rutik_strapi_log_group.name
        awslogs-region        = "us-east-2"
        awslogs-stream-prefix = "ecs/rutik-strapi"
      }
    }
  }])
}

resource "aws_lb" "alb" {
  name               = "rutik-strapi-alb-task11"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.rutik_alb_sg.id]
  subnets = [
    "subnet-0f768008c6324831f",  # Same as ECS
    "subnet-0cc2ddb32492bcc41"   
  ]
}
resource "aws_lb_target_group" "ecs_blue" {
  name        = "rutik-tg-blue-11"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = "vpc-06ba36bca6b59f95e"
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "ecs_green" {
  name        = "rutik-tg-green-11"
  port        = 1337
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "vpc-06ba36bca6b59f95e"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "listener-ecs" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_blue.arn
  }
}

resource "aws_lb_listener" "listener-ecs-test" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_green.arn
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "rutik-strapi-ecs-sg"
  description = "Allow HTTP"
  vpc_id      = "vpc-06ba36bca6b59f95e"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow ALB to access ECS task on port 1337"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    security_groups = [ aws_security_group.rutik_alb_sg.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_security_group" "rutik_alb_sg" {
  name        = "rutik-strapi-alb-sg"
  description = "Allow inbound HTTP from the internet"
  vpc_id      = "vpc-06ba36bca6b59f95e"

  ingress {
    description = "Allow HTTP traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from the internet"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow test listener port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

resource "aws_codedeploy_app" "strapi_app" {
  name             = "StrapiCodeDeployApp-rutik"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "strapi_deployment_group" {
  app_name              = aws_codedeploy_app.strapi_app.name
  deployment_group_name = "StrapiDeployGroup"
  service_role_arn      = aws_iam_role.codedeploy_ecs_role.arn

  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }


  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.strapi_cluster.name
    service_name = aws_ecs_service.strapi_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.listener-ecs.arn]
      }
      test_traffic_route {
        listener_arns = [aws_lb_listener.listener-ecs-test.arn]
      }
      target_group {
        name = aws_lb_target_group.ecs_blue.name
      }
      target_group {
        name = aws_lb_target_group.ecs_green.name
      }
    }
  }
}

resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service-rutik"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }
  network_configuration {
    subnets          =  ["subnet-0f768008c6324831f", "subnet-0cc2ddb32492bcc41"]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_blue.arn   # or green
    container_name   = "rutik-strapi"
    container_port   = 1337
  }
  depends_on = [ aws_lb_listener.listener-ecs ]
  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
}

resource "aws_iam_role" "codedeploy_ecs_role" {
  name = "rutik-CodeDeployECSRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"

}
resource "aws_iam_role_policy" "codedeploy_ecs_permissions" {
  name = "CodeDeployECSInlinePolicy"
  role = aws_iam_role.codedeploy_ecs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:RegisterTaskDefinition",
          "elasticloadbalancing:DescribeTargetGroups",
          "ecs:DescribeTaskDefinition",          # Missing
          "ecs:ListTasks",                       # Missing
          "ecs:DescribeTasks",              
          "elasticloadbalancing:DescribeTargetHealth",  # Missing
          "elasticloadbalancing:RegisterTargets",       # Missing
          "elasticloadbalancing:DeregisterTargets", 
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule",
          "lambda:InvokeFunction",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "s3:GetObject",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}
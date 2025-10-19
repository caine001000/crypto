
resource "aws_ecs_cluster" "tokyo" {
  provider = aws.tokyo
  name     = "tokyo-proxy-cluster"

  tags = {
    Name = "tokyo-proxy-cluster"
  }
}

resource "aws_cloudwatch_log_group" "proxy" {
  provider          = aws.tokyo
  name              = "/ecs/tokyo-proxy"
  retention_in_days = 7

  tags = {
    Name = "tokyo-proxy-logs"
  }
}

resource "aws_ecs_task_definition" "proxy" {
  provider                 = aws.tokyo
  family                   = "tokyo-http-proxy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name  = "tinyproxy"
      image = "vimagick/tinyproxy:latest"
      portMappings = [
        {
          containerPort = 8888
          hostPort      = 8888
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ALLOWED"
          value = "10.1.0.0/16"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.proxy.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "proxy"
        }
      }
    }
  ])

  tags = {
    Name = "tokyo-proxy-task"
  }
}

resource "aws_security_group" "fargate_proxy" {
  provider    = aws.tokyo
  name        = "fargate-proxy-sg"
  description = "Security group for Fargate proxy"
  vpc_id      = aws_vpc.tokyo.id

  ingress {
    description = "HTTP Proxy from Singapore"
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fargate-proxy-sg"
  }
}

resource "aws_ecs_service" "proxy" {
  provider        = aws.tokyo
  name            = "tokyo-proxy-service"
  cluster         = aws_ecs_cluster.tokyo.id
  task_definition = aws_ecs_task_definition.proxy.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.tokyo_public.id]
    security_groups  = [aws_security_group.fargate_proxy.id]
    assign_public_ip = true
  }

  tags = {
    Name = "tokyo-proxy-service"
  }
}

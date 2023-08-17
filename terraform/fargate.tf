data "aws_vpc" "default" {
  default = true
}

# data "aws_subnets" "default" {
#   vpc_id = data.aws_vpc.default.id
# }

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "example" {
  for_each = toset(data.aws_subnets.example.ids)
  id       = each.value
}

# ... Your existing Terraform code ...

# ECS Cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name    = "my-container"
    image   = "curlimages/curl:latest"
    command = ["/bin/sh", "-c", "curl ipinfo.io/ip; exit 123"]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-region" = local.region
        "awslogs-group"  = aws_cloudwatch_log_group.ecs_logs.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ECS IAM Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Effect = "Allow",
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Lambda IAM permissions to start the ECS task
resource "aws_iam_policy" "lambda_start_ecs_policy" {
  name        = "LambdaStartECSPolicy"
  description = "Allows Lambda to start ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "ecs:RunTask"
      ],
      Resource = "*",
      Effect   = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ecs_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name  # Assuming this is the IAM role your Lambda function is using
  policy_arn = aws_iam_policy.lambda_start_ecs_policy.arn
}

output "subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.example : s.cidr_block]
}
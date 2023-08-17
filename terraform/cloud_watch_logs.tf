resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "ecs-fargate-logs"
  retention_in_days = 14 # Choose the retention policy that fits your needs.
}

resource "aws_iam_policy" "ecs_logging" {
  name        = "ECSLogging"
  description = "Allow ECS to log to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_logging" {
  policy_arn = aws_iam_policy.ecs_logging.arn
  role       = aws_iam_role.ecs_execution_role.name
}
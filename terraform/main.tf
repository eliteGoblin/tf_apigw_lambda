locals {
    region = "ap-southeast-2"
}

provider "aws" {
  region = local.region
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_lambda_function" "my_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "my_lambda_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda/ecs_task_runner.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_api_gateway_rest_api" "my_api" {
  name        = "MyAPI"
  description = "My API"
  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.api_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.api_lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "prod"
  description = "My API deployment"
}

output "api_url" {
  value = "https://${aws_api_gateway_rest_api.my_api.id}.execute-api.${local.region}.amazonaws.com/prod/hello"
}

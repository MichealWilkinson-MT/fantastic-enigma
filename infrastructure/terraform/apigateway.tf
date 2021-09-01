data "aws_iam_policy_document" "api_gateway_logs" {
    statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "api_gateway_publish_sqs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]
    resources = [ aws_sqs_queue.import-queue.arn ]
  }
}

data "aws_iam_policy_document" "api_gateway_invoke_lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:invokeFunction"
    ]
    resources = ["arn:aws:lambda:eu-west-2:261219435789:function:fantastic-enigma-dev-dynamodb-reader"]
  }
}

data "aws_iam_policy_document" "api_gateway_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "apigateway.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "api_gateway_invoke_lambda_policy" {
  name = "API_Gateway_Trigger_Lambdas"
  policy = data.aws_iam_policy_document.api_gateway_invoke_lambda_policy.json
}

resource "aws_iam_policy" "api_gateway_logs_policy" {
  name = "apiGatewayLogsPolicy"
  policy = data.aws_iam_policy_document.api_gateway_logs.json
}

resource "aws_iam_policy" "api_gateway_publish_sqs_policy" {
  name = "apiGatewayPublishSQSPolicy"
  policy = data.aws_iam_policy_document.api_gateway_publish_sqs_policy.json
}

resource "aws_iam_role" "api_gateway_role" {
  name = "MedichecksApiGatewayRole"
  managed_policy_arns = [
    aws_iam_policy.api_gateway_publish_sqs_policy.arn,
    aws_iam_policy.api_gateway_logs_policy.arn,
    aws_iam_policy.api_gateway_invoke_lambda_policy.arn
  ]
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role_policy.json
}
resource "aws_apigatewayv2_api" "api_gateway" {
  name = "FantasticEnigmaApiv2"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "api_gateway_dev_stage" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  name = "dev"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "api_gateway_post_hash_integration" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  request_parameters = { 
    "QueueUrl" : aws_sqs_queue.import-queue.url, 
    "MessageBody" : "$request.body.string",
    "MessageGroupId" : "MyGroupId"
  }
  credentials_arn = aws_iam_role.api_gateway_role.arn
}

resource "aws_apigatewayv2_route" "api_gateway_post_hash_route" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  route_key = "POST /hash"
  target = "integrations/${aws_apigatewayv2_integration.api_gateway_post_hash_integration.id}"
}

resource "aws_apigatewayv2_integration" "api_gateway_post_read_integration" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"
  integration_uri = "arn:aws:lambda:eu-west-2:261219435789:function:fantastic-enigma-dev-dynamodb-reader"
  credentials_arn = aws_iam_role.api_gateway_role.arn
}

resource "aws_apigatewayv2_route" "api_gateway_post_read_route" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /hash"
  target = "integrations/${aws_apigatewayv2_integration.api_gateway_post_read_integration.id}"
}
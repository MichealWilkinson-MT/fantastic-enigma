data "aws_iam_policy_document" "hash_function_policy_doc" {
  statement {
    sid = "DatabaseAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem"
    ]
    effect    = "Allow"
    resources = [aws_dynamodb_table.dynamodb.arn]
  }

  statement {
    sid = "ConsumeQueue"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:sqs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_acc.account_id}:*"
    ]
  } 

  statement {
    sid = "WriteLogs"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

data "aws_iam_policy_document" "dynamodbwriter_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "hash_function_policy" {
  name   = "MedichecksDatabaseWriteLambdaPolicy_${var.stage}"
  policy = data.aws_iam_policy_document.hash_function_policy_doc.json
}

resource "aws_iam_role" "hash_function_role" {
  name = "DatabaseWriter_${var.stage}"
  managed_policy_arns = [
    aws_iam_policy.hash_function_policy.arn
  ]
  assume_role_policy = data.aws_iam_policy_document.dynamodbwriter_assume_role_policy.json
}

// lambda then provisioned by serverless
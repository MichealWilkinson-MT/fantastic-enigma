data "aws_iam_policy_document" "read_function_policy_doc" {
  statement {
    sid = "DatabaseAccess"
    actions = [
      "dynamodb:GetItem"
    ]
    effect    = "Allow"
    resources = [aws_dynamodb_table.dynamodb.arn]
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

data "aws_iam_policy_document" "dynamodbreader_assume_role_policy" {
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

resource "aws_iam_policy" "read_function_policy" {
  name   = "MedichecksDatabaseReaderLambdaPolicy"
  policy = data.aws_iam_policy_document.read_function_policy_doc.json
}

resource "aws_iam_role" "read_function_role" {
  name = "DatabaseReader"
  managed_policy_arns = [
    aws_iam_policy.read_function_policy.arn
  ]
  assume_role_policy = data.aws_iam_policy_document.dynamodbreader_assume_role_policy.json
}

// lambda then provisioned by serverless
data "aws_iam_policy_document" "sqs_trigger_lambda" {
  statement {
    actions   = ["lambda:CreateEventSourceMapping", "lambda:ListEventSourceMappings", "lambda:ListFunctions"]
    effect    = "Allow"
    resources = ["arn:aws:lambda:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_acc.account_id}:function:*"]
  }
}

resource "aws_sqs_queue" "import-queue" {
  name                        = "medichecks-import-q.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  policy = data.aws_iam_policy_document.sqs_trigger_lambda.json
}
resource "aws_ssm_parameter" "import-queue-arn" {
  name        = "/fantastic-enigma/${var.stage}/inputQueue/arn"
  description = "arn for the import queue in the ${var.stage} environment"
  type        = "SecureString"
  value       = aws_sqs_queue.import-queue.arn
}

resource "aws_ssm_parameter" "import-lambda-role-arn" {
  name        = "/fantastic-enigma/${var.stage}/lambda/role-arn"
  description = "arn for the lambda role in the ${var.stage} environment"
  type        = "SecureString"
  value       = aws_iam_role.hash_function_role.arn
}

resource "aws_ssm_parameter" "read-lambda-role-arn" {
  name        = "/fantastic-enigma/${var.stage}/lambda/read-role-arn"
  description = "arn for the lambda role in the ${var.stage} environment"
  type        = "SecureString"
  value       = aws_iam_role.read_function_role.arn
}

resource "aws_ssm_parameter" "database-region" {
  name        = "/fantastic-enigma/${var.stage}/database-region"
  description = "The region where the database is located"
  type        = "SecureString"
  value       = data.aws_region.aws_region.name
}

resource "aws_ssm_parameter" "database-name" {
  name        = "/fantastic-enigma/${var.stage}/database-name"
  description = "The database table name"
  type        = "SecureString"
  value       = aws_dynamodb_table.dynamodb.name
}
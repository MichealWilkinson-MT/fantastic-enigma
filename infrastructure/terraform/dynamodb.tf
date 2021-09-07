resource "aws_dynamodb_table" "dynamodb" {
  name           = "fantastic-enigma-shas-${var.stage}"
  hash_key       = "InputString"
  write_capacity = 2
  read_capacity  = 2
  attribute {
    name = "InputString"
    type = "S"
  }
}
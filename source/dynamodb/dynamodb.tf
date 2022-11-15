resource "aws_dynamodb_table" "raw-client-data" {
  name           = "RawClientData"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Id"
  range_key      = "SearchState"

  attribute {
    name = "Id"
    type = "S"
  }

  attribute {
    name = "SearchState"
    type = "S"
  }
}

resource "aws_dynamodb_table" "client-data" {
  name           = "ClientData"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "SearchSuburb"
  range_key      = "SearchState"

  attribute {
    name = "SearchSuburb"
    type = "S"
  }

  attribute {
    name = "SearchState"
    type = "S"
  }
}
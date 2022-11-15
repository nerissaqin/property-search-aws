resource "aws_glue_catalog_database" "real_estate_database" {
  name = "real_estate_database"
}

resource "aws_glue_crawler" "client_raw_data_crawler" {
  database_name = aws_glue_catalog_database.real_estate_database.name
  name          = "ClientRawDataCrawler"
  role          = "arn:aws:iam::679291055404:role/LabRole"
  schedule      = "cron(15 11 1 * ? *)"
  dynamodb_target {
    path = "RawClientData"
  }
}

resource "aws_glue_job" "client_data_process_job" {
  name     = "ClientDataProcessJob"
  role_arn = "arn:aws:iam::679291055404:role/LabRole"
  glue_version = "3.0"
  number_of_workers = 2
  worker_type = "G.1X"

  command {
    script_location = "s3://${aws_s3_bucket.glub-script.bucket}/script.py"
  }
  default_arguments = {
    "--job-language" = "python"
  }
}

resource "aws_glue_trigger" "client_data_process_trigger" {
  name     = "client_data_process_trigger"
  schedule = "cron(03 02 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.client_data_process_job.name
  }
}

resource "aws_s3_bucket" "glub-script" {
  bucket = "my-glue-script-bucket-for-assignment-1"
}

resource "aws_s3_bucket_acl" "glub-script-acl" {
  bucket = aws_s3_bucket.glub-script.id
  acl    = "private"
}
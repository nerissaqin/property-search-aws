//elastic beanstalk
resource "aws_elastic_beanstalk_application" "application" {
  name        = "my-awesome-application"
} 

resource "aws_elastic_beanstalk_environment" "environment" {
  name                = "my-awesome-environment"
  application         = aws_elastic_beanstalk_application.application.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.13 running Docker"

  setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "IamInstanceProfile"
        value     = "LabInstanceProfile"
      }
}

resource "aws_s3_bucket" "elasticbeanstalkcode" {
  bucket = "huipinelasticbeanstalkcodeassignment1"

  tags = {
    Name        = "elasticbeanstalk_code_assignment_1"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "elasticbeanstalk_code_acl" {
  bucket = aws_s3_bucket.elasticbeanstalkcode.id
  acl    = "private"
}
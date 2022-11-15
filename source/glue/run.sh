##!/bin/bash
aws s3 cp ./script.py s3://my-glue-script-bucket-for-assignment-1/
terraform init
terraform apply
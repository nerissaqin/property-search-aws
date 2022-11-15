#!/bin/bash
terraform init
terraform plan -out terraform.tfstate.plan
terraform apply terraform.tfstate.plan
echo "if it doesn't work. try terraform init"
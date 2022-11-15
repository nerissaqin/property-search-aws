This is a terraform script for deploying 2 dynamodb tables.

## included
- dynamodb table: client raw data
- dynamodb table: client data

## steps
- deploy to aws: `./run.sh`
- destroy dynamodb tables: `terraform destroy`
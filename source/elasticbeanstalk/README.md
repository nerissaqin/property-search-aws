This is a terraform script for deploying elastic beanstalk related resources. We use it to build client front end.

## Includes
- elastic beanstalk application
- elastic beanstalk environment (where our app it is)
- s3 for store dockerrun config
- ecr for store images

## Steps
- test in local: `./run_local.sh`. Then goto http://localhost:3000
- if all good remove the local docker container: `docker rm -f suburb`
- now we know the container is working. We deploy the infrastructure with terraform: `terraform init`, `terraform plan` and then `terraform apply` or run `./terraform_deploy.sh` (only need to run once)
- deploy app to aws: `./app_deploy.sh`. it creates an image and push to ecr. it upload the config file to s3 and ask eb to read config from s3 and pull image from ecr.
- if you don't need it anymore, you can destroy the infrastructure with terraform: `terraform destroy`
- eb website url: http://my-awesome-environment.eba-ap3fiinm.us-east-1.elasticbeanstalk.com/
- if the ebs application environment is recreated, you will need to go to the new environment to find out a new dns name.

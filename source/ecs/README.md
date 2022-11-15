This is a terraform script for deploying ecs related resources and app (docker). ECS (fargate) is used as frontend for admin website for viewing client behaviour anasysis data, so that we can continue to improve our website and better help serve our clients.

## include
- cloudwatch log
- security group
- ecs

## Steps
- test in the local. Run `./run_local.sh`
- to deploy (both infrastructure and app): `./deploy.sh`. This script only works for macbook m1, as macbook m1 build different kind of docker image (due to different chips). 
- public ip: 52.90.228.3 . The public ip will be changed if the task (container) is replaced in ecs. To get a new one, go to ecs --> click our cluster --> click service tab --> click our service --> click task tab --> click our task --> you will see the public ip in the details page.
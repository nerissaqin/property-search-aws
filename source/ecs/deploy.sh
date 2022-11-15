#!/bin/bash
set -e
cd "$(dirname "$0")"
VERSION=`cat ./version.txt`
((VERSION+=1))

APP=my-awesome-application
APP_ENV=my-awesome-environment
BUCKET=huipinelasticbeanstalkcodeassignment1
ACCOUNT=679291055404
REGION=us-east-1
IMAGE=realestate-admin




# aws login
aws ecr get-login-password --region $REGION| docker login --username AWS --password-stdin $ACCOUNT.dkr.ecr.$REGION.amazonaws.com

# Build the image
# for mac m1
docker buildx build --tag $ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$IMAGE:$VERSION -o type=image --platform=linux/arm64,linux/amd64 ./docker
# for mac/linux
# docker build -t $ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$IMAGE:$VERSION .
# Create repo
aws ecr describe-repositories --repository-names $IMAGE > log.txt|| aws ecr create-repository \
    --repository-name $IMAGE > log.txt
# Push to AWS Elastic Container Registry
# for mac m1
docker buildx build --push --tag $ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$IMAGE:$VERSION --platform=linux/arm64,linux/amd64 ./docker
# for mac/linux
# docker push $ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$IMAGE:$VERSION
# Update Dockerrun.aws.json file
# Replace the <TAG> with the your version number
sed "s/<TAG>/$VERSION/" ecs.tf.template > ecs.tf

terraform init
terraform apply

echo $VERSION > ./version.txt
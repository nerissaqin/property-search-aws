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
IMAGE=realestate
ZIP=$IMAGE.$VERSION.zip




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
sed "s/<TAG>/$VERSION/" Dockerrun.aws.json.template > Dockerrun.aws.json

# Zip up the Dockerrun file
zip -r $ZIP Dockerrun.aws.json

# Send zip to S3 Bucket
aws s3 cp $ZIP  s3://$BUCKET/$ZIP


# Create a new application version with the zipped up Dockerrun file
aws elasticbeanstalk create-application-version --application-name $APP --version-label $VERSION --source-bundle S3Bucket=$BUCKET,S3Key=$ZIP >> log.txt

# Update the environment to use the new application version
aws elasticbeanstalk update-environment --environment-name $APP_ENV --version-label $VERSION >> log.txt

echo $VERSION > ./version.txt

#!/bin/bash

# Configuration
REGION="us-east-1"
ACCOUNT_ID="your-aws-account-id"
REPOSITORY_NAME="fine-tuned-translator"
IMAGE_TAG="latest"

echo "Starting Docker build and push process for fine-tuned model..."

# Build Docker image (this will include your finetuned_en_fr directory)
docker build -t $REPOSITORY_NAME:$IMAGE_TAG .

if [ $? -ne 0 ]; then
    echo "Docker build failed"
    exit 1
fi

echo "Docker build successful"

# Create ECR repository
aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $REGION > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Creating ECR repository..."
    aws ecr create-repository --repository-name $REPOSITORY_NAME --region $REGION
    echo "ECR repository created"
else
    echo "ECR repository already exists"
fi

# Get ECR login credentials
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Tag and push image
docker tag $REPOSITORY_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG

if [ $? -eq 0 ]; then
    echo "Fine-tuned model image pushed successfully to ECR"
    echo "Image URI: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG"
else
    echo "Image push failed"
    exit 1
fi
# Make scripts executable
chmod +x build_and_push.sh
chmod +x deploy.sh

# Build and push your fine-tuned model to ECR
./build_and_push.sh

# Deploy with GPU-optimized template
aws cloudformation deploy \
    --stack-name fine-tuned-translator \
    --template-file cloudformation-gpu-template.yaml \
    --parameter-overrides ImageUrl=YOUR_ECR_IMAGE_URI \
    --capabilities CAPABILITY_IAM \
    --region us-east-1

# Test your deployed fine-tuned model
python test_local.py
#!/bin/bash

set -e

##############################################
# Configuration
##############################################

FUNCTION_NAME="visitor-counter"
ROLE_NAME="visitor-counter-role"
TABLE_NAME="VisitorCounter"
RUNTIME="python3.13"
HANDLER="lambda_function.lambda_handler"

REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Region      : $REGION"
echo "Account ID  : $ACCOUNT_ID"

##############################################
# Create IAM Role
##############################################

echo "Creating IAM Role..."

aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://trust-policy.json || true

##############################################
# Attach CloudWatch Policy
##############################################

aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

##############################################
# Create DynamoDB Policy
##############################################

cat > dynamodb-policy.json <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Action":[
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Resource":"arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/$TABLE_NAME"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name DynamoDBAccess \
    --policy-document file://dynamodb-policy.json

##############################################
# Wait for IAM propagation
##############################################

echo "Waiting 15 seconds for IAM..."

sleep 15

##############################################
# Package Lambda
##############################################

zip lambda.zip lambda_function.py

##############################################
# Create Lambda
##############################################

aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime $RUNTIME \
    --role arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME \
    --handler $HANDLER \
    --zip-file fileb://lambda.zip \
    --timeout 10 \
    --memory-size 128 \
    --environment Variables="{TABLE_NAME=$TABLE_NAME}"

##############################################
# Verify Lambda
##############################################

aws lambda get-function \
    --function-name $FUNCTION_NAME

echo ""
echo "======================================"
echo "Lambda Successfully Created"
echo "======================================"

aws lambda get-function \
    --function-name $FUNCTION_NAME \
    --query "Configuration.FunctionArn" \
    --output text

echo ""
echo "Done."

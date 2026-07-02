#!/bin/bash

# ==============================
# Configuration
# ==============================

FUNCTION_NAME="visitor-counter"
API_NAME="VisitorCounterAPI"
STAGE_NAME="prod"
ROUTE_KEY="GET /count"

# ==============================
# Get AWS Details
# ==============================

REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Region      : $REGION"
echo "Account ID  : $ACCOUNT_ID"

# ==============================
# Get Lambda ARN
# ==============================

LAMBDA_ARN=$(aws lambda get-function \
    --function-name $FUNCTION_NAME \
    --query "Configuration.FunctionArn" \
    --output text)

echo "Lambda ARN: $LAMBDA_ARN"

# ==============================
# Create HTTP API
# ==============================

API_ID=$(aws apigatewayv2 create-api \
    --name $API_NAME \
    --protocol-type HTTP \
    --query ApiId \
    --output text)

echo "API ID: $API_ID"

# ==============================
# Create Lambda Integration
# ==============================

INTEGRATION_ID=$(aws apigatewayv2 create-integration \
    --api-id $API_ID \
    --integration-type AWS_PROXY \
    --integration-uri $LAMBDA_ARN \
    --payload-format-version 2.0 \
    --query IntegrationId \
    --output text)

echo "Integration ID: $INTEGRATION_ID"

# ==============================
# Create Route
# ==============================

aws apigatewayv2 create-route \
    --api-id $API_ID \
    --route-key "$ROUTE_KEY" \
    --target integrations/$INTEGRATION_ID

echo "Route Created"

# ==============================
# Create Stage
# ==============================

aws apigatewayv2 create-stage \
    --api-id $API_ID \
    --stage-name $STAGE_NAME \
    --auto-deploy

echo "Stage Created"

# ==============================
# Enable CORS
# ==============================

aws apigatewayv2 update-api \
    --api-id $API_ID \
    --cors-configuration AllowOrigins="*",AllowMethods="GET,OPTIONS",AllowHeaders="Content-Type"

echo "CORS Enabled"

# ==============================
# Allow API Gateway to Invoke Lambda
# ==============================

aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id apigateway-access \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"

echo "Lambda Permission Added"

# ==============================
# Display API URL
# ==============================

echo ""
echo "========================================="
echo "API Successfully Created"
echo "========================================="
echo "Invoke URL:"
echo "https://$API_ID.execute-api.$REGION.amazonaws.com/$STAGE_NAME/count"
echo "========================================="

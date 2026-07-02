A good production-style AWS Lambda project should demonstrate serverless architecture, multiple AWS service integrations, IAM permissions, logging, monitoring, and deployment from both the AWS Console and AWS CLI.

# 🚀 Project: Serverless Visitor Counter using AWS Lambda

## Architecture

```text
                    User
                      │
                      ▼
             Amazon API Gateway
                      │
                      ▼
               AWS Lambda (Python)
                      │
         ┌────────────┴────────────┐
         │                         │
         ▼                         ▼
   Amazon DynamoDB          Amazon CloudWatch
 (Store Visitor Count)        Logs & Metrics
         │
         ▼
     Static Website
      (Amazon S3)
```

## AWS Services Used

| Service                            | Purpose             |
| ---------------------------------- | ------------------- |
| AWS Lambda                         | Backend logic       |
| Amazon API Gateway                 | REST API            |
| Amazon DynamoDB                    | Store visitor count |
| Amazon S3                          | Static website      |
| Amazon CloudWatch                  | Monitoring          |
| AWS Identity and Access Management | Permissions         |

---

# Project Structure

```text
visitor-counter/

│── lambda_function.py
│── requirements.txt
│── policy.json
│── index.html
│── style.css
│── script.js
│── template.yaml (Optional SAM)
│── README.md
```

---

# Workflow

```text
User Opens Website

↓

JavaScript Calls API Gateway

↓

Lambda Executes

↓

Read Current Count

↓

Increment Count

↓

Update DynamoDB

↓

Return JSON

↓

Website Displays Visitor Count
```

---

# Step 1 Create DynamoDB Table

Table Name

```
VisitorCounter
```

Partition Key

```
id (String)
```

Insert Item

```json
{
"id":"website",
"count":0
}
```

---

# Step 2 Lambda Function (Python)

```python
import json
import boto3
from decimal import Decimal

table = boto3.resource("dynamodb").Table("VisitorCounter")

def lambda_handler(event, context):

    response = table.update_item(
        Key={"id":"website"},
        UpdateExpression="SET #c = if_not_exists(#c,:start)+:inc",
        ExpressionAttributeNames={
            "#c":"count"
        },
        ExpressionAttributeValues={
            ":inc":1,
            ":start":0
        },
        ReturnValues="UPDATED_NEW"
    )

    count=int(response["Attributes"]["count"])

    return {
        "statusCode":200,
        "headers":{
            "Access-Control-Allow-Origin":"*"
        },
        "body":json.dumps({
            "visitors":count
        })
    }
```

---

# requirements.txt

```
boto3
```

---

# IAM Policy

```json
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Action":[
        "dynamodb:UpdateItem",
        "dynamodb:GetItem"
      ],
      "Resource":"arn:aws:dynamodb:*:*:table/VisitorCounter"
    }
  ]
}
```

---

# API Response

```json
{
  "visitors":104
}
```

---

# Static Website

```html
<!DOCTYPE html>
<html>
<head>
<title>Visitor Counter</title>
</head>

<body>

<h1>Cloudnautic Visitor Counter</h1>

<h2 id="count">Loading...</h2>

<script src="script.js"></script>

</body>

</html>
```

---

# JavaScript

```javascript
fetch("YOUR_API_GATEWAY_URL")
.then(res=>res.json())
.then(data=>{
    const result=JSON.parse(data.body);
    document.getElementById("count").innerHTML=result.visitors;
});
```

---

# AWS Console Deployment

## Create DynamoDB

```
AWS Console

↓

DynamoDB

↓

Create Table

↓

VisitorCounter

↓

id (String)
```

---

## Create Lambda

```
AWS Console

↓

Lambda

↓

Create Function

↓

Author From Scratch

↓

Python 3.13

↓

visitor-counter
```

Paste Python code.

Deploy.

---

## Permissions

Attach DynamoDB policy.

---

## Create API Gateway

```
HTTP API

↓

Lambda Integration

↓

Enable CORS

↓

Deploy
```

Copy endpoint.

---

## Upload Website

```
S3

↓

Enable Static Website Hosting

↓

Upload

index.html

script.js

style.css
```

Update API URL inside script.js.

---

# AWS CLI Deployment

## Create Table

```bash
aws dynamodb create-table \
--table-name VisitorCounter \
--attribute-definitions AttributeName=id,AttributeType=S \
--key-schema AttributeName=id,KeyType=HASH \
--billing-mode PAY_PER_REQUEST
```

Insert Initial Record

```bash
aws dynamodb put-item \
--table-name VisitorCounter \
--item '{"id":{"S":"website"},"count":{"N":"0"}}'
```

---

## Create ZIP

```bash
zip function.zip lambda_function.py
```

---

## Create IAM Role

```bash
aws iam create-role \
--role-name LambdaVisitorRole \
--assume-role-policy-document file://trust.json
```

Attach Policy

```bash
aws iam attach-role-policy \
--role-name LambdaVisitorRole \
--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

---

## Create Lambda

```bash
aws lambda create-function \
--function-name visitor-counter \
--runtime python3.13 \
--handler lambda_function.lambda_handler \
--zip-file fileb://function.zip \
--role IAM_ROLE_ARN
```

---

## Update Lambda

```bash
zip function.zip lambda_function.py

aws lambda update-function-code \
--function-name visitor-counter \
--zip-file fileb://function.zip
```

---

## Invoke Lambda

```bash
aws lambda invoke \
--function-name visitor-counter \
output.json
```

---

## Create API Gateway

You can use the AWS CLI to create an HTTP API, integrate it with Lambda, and create a default stage. (This involves several commands for API creation, integration, route configuration, permission, and deployment.)

---

# Testing

```bash
curl https://YOUR_API_ID.execute-api.REGION.amazonaws.com/
```

Output

```json
{
  "visitors":15
}
```

---

# CloudWatch Monitoring

View:

* Lambda execution logs
* Invocation count
* Errors
* Duration
* Throttles
* Concurrent executions

---

# Security Best Practices

* Use least-privilege IAM policies.
* Store configuration (such as table names) in Lambda environment variables instead of hardcoding.
* Enable API Gateway throttling and CORS only for trusted origins.
* Turn on CloudWatch log retention policies.
* Consider adding authentication (such as JWT authorizers) if the API is not public.

---

# Production Enhancements

* Add a custom domain with Amazon Route 53.
* Use Amazon CloudFront in front of the S3 website for caching and HTTPS.
* Manage infrastructure with AWS CloudFormation or Terraform.
* Store secrets in AWS Secrets Manager if needed.
* Configure CloudWatch alarms and notifications through Amazon Simple Notification Service.
* Add CI/CD using GitHub Actions or AWS CodePipeline.

This project is an excellent portfolio example because it demonstrates end-to-end serverless development, integrating Lambda, API Gateway, DynamoDB, S3, IAM, and CloudWatch while covering both AWS Console and CLI deployment workflows.

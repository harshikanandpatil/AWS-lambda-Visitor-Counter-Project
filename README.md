A **Visitor Counter** is one of the easiest and most practical AWS Lambda projects. It demonstrates serverless architecture, API integration, database usage, and a simple web UI.

# AWS Visitor Counter Project

## Objective

Create a website that displays the total number of visitors.

Each page refresh increments the visitor count automatically.

---

# Architecture

```text
                User
                  │
                  ▼
          Static Website (HTML/CSS/JS)
                  │
          JavaScript Fetch API
                  │
                  ▼
            API Gateway
                  │
                  ▼
             AWS Lambda
                  │
          Read/Update Counter
                  │
                  ▼
            DynamoDB Table
```

---

# AWS Services Used

| Service     | Purpose             |
| ----------- | ------------------- |
| AWS Lambda  | Backend logic       |
| API Gateway | REST API            |
| DynamoDB    | Store visitor count |
| S3          | Static Website      |
| IAM         | Permissions         |
| CloudWatch  | Logs                |

---

# Project Flow

```text
Open Website

↓

JavaScript calls API Gateway

↓

API Gateway invokes Lambda

↓

Lambda reads current count

↓

Lambda increments count

↓

Store updated count

↓

Return latest count

↓

Website displays count
```

---

# Folder Structure

```text
visitor-counter/

│
├── lambda/
│      lambda_function.py
│
├── website/
│      index.html
│      style.css
│      script.js
│
├── architecture.png
│
└── README.md
```

Repository Name

```text
aws-lambda-visitor-counter
```

---

# Step 1 Create DynamoDB Table

Table Name

```text
VisitorCounter
```

Partition Key

```text
id
```

Value

```text
visitor
```

Example

| id      | count |
| ------- | ----- |
| visitor | 0     |

---

# Step 2 Create IAM Role

Attach

```
AWSLambdaBasicExecutionRole
```

Add DynamoDB permissions

```
GetItem
UpdateItem
PutItem
```

---

# Step 3 Create Lambda Function

Runtime

```
Python 3.13
```

Name

```
visitor-counter
```

---

## Lambda Code

```python
import json
import boto3

table = boto3.resource('dynamodb').Table('VisitorCounter')

def lambda_handler(event, context):

    response = table.update_item(
        Key={'id':'visitor'},
        UpdateExpression="ADD #c :inc",
        ExpressionAttributeNames={
            "#c":"count"
        },
        ExpressionAttributeValues={
            ":inc":1
        },
        ReturnValues="UPDATED_NEW"
    )

    count = int(response["Attributes"]["count"])

    return {
        "statusCode":200,
        "headers":{
            "Access-Control-Allow-Origin":"*"
        },
        "body":json.dumps({
            "count":count
        })
    }
```

---

# Step 4 Create API Gateway

```
HTTP API
```

Route

```
GET /count
```

Integration

```
Lambda
```

Enable

```
CORS
```

---

# Step 5 Website

## index.html

```html
<!DOCTYPE html>
<html>

<head>
    <title>Visitor Counter</title>
    <link rel="stylesheet" href="style.css">
</head>

<body>

<h1>AWS Visitor Counter</h1>

<div class="card">

<p>Total Visitors</p>

<h2 id="count">Loading...</h2>

</div>

<script src="script.js"></script>

</body>

</html>
```

---

## style.css

```css
body{
    font-family:Arial;
    background:#f5f5f5;
    text-align:center;
    margin-top:120px;
}

.card{

width:300px;
margin:auto;
padding:30px;
background:white;
border-radius:10px;
box-shadow:0 0 10px gray;

}

h2{
font-size:45px;
color:#0073e6;
}
```

---

## script.js

Replace with your API URL.

```javascript
fetch("https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/count")
.then(response=>response.json())
.then(data=>{
document.getElementById("count").innerHTML=data.count;
});
```

---

# Step 6 Upload Website

```
S3
```

Enable

```
Static Website Hosting
```

Upload

```
index.html
style.css
script.js
```

---

# Step 7 Test

Open

```
Website URL
```

Every refresh

```
1

2

3

4

5
```

Counter increases.

---

# Architecture Diagram

```text
                Browser
                   │
                   ▼
          S3 Static Website
                   │
          JavaScript Fetch()
                   │
                   ▼
             API Gateway
                   │
                   ▼
              AWS Lambda
                   │
          Update Visitor Count
                   │
                   ▼
              DynamoDB
```

---

# Sample Output

```text
-----------------------------
 AWS Visitor Counter
-----------------------------

Total Visitors

1245
```

---

# Code Explanation

## lambda/lambda_function.py

```python
import json
import boto3
import os
from botocore.exceptions import ClientError
```

| Import | Purpose |
| --- | --- |
| `json` | Serialize the HTTP response body to a JSON string |
| `boto3` | AWS SDK for Python — used to talk to DynamoDB |
| `os` | Read the `TABLE_NAME` environment variable at runtime |
| `ClientError` | Catch DynamoDB-specific errors gracefully |

---

```python
dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("TABLE_NAME", "visitor-counter")
```

- `boto3.resource("dynamodb")` creates a high-level DynamoDB client once at **cold-start** time (outside the handler) so it is reused across warm invocations — this improves performance.
- `TABLE_NAME` is read from an **environment variable** so the same code works in dev, staging, and production without changes.

---

```python
def lambda_handler(event, context):
    table = dynamodb.Table(TABLE_NAME)
```

- `lambda_handler` is the **entry point** AWS calls every time the function is invoked.
- `event` carries data from the API Gateway request (headers, query params, etc.).
- `context` carries runtime metadata (function name, remaining time, etc.).
- `dynamodb.Table(TABLE_NAME)` returns a reference to the DynamoDB table.

---

```python
    response = table.update_item(
        Key={"id": "visitor_count"},
        UpdateExpression="ADD #count :increment",
        ExpressionAttributeNames={"#count": "count"},
        ExpressionAttributeValues={":increment": 1},
        ReturnValues="UPDATED_NEW",
    )
```

| Parameter | Explanation |
| --- | --- |
| `Key` | Identifies the single row in the table using the partition key `id = "visitor_count"` |
| `UpdateExpression` | `ADD` atomically increments a numeric attribute — safe under concurrent requests |
| `ExpressionAttributeNames` | `#count` is an alias for the reserved word `count` (DynamoDB reserves it) |
| `ExpressionAttributeValues` | `:increment` is the value `1` — how much to add each visit |
| `ReturnValues="UPDATED_NEW"` | Returns only the updated attribute so we can read the new count |

> **Why `ADD` instead of `SET`?**
> `ADD` is an **atomic increment** — if two users visit at the same millisecond, both increments are applied correctly. `SET count = count + 1` would require a read-modify-write cycle and could lose updates.

---

```python
    count = int(response["Attributes"]["count"])
```

DynamoDB returns numbers as `Decimal` objects. Casting to `int` makes it JSON-serializable.

---

```python
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
            "Content-Type": "application/json",
        },
        "body": json.dumps({"visitorCount": count}),
    }
```

- `statusCode: 200` tells API Gateway the request succeeded.
- **CORS headers** (`Access-Control-Allow-Origin: *`) allow the browser to call the API from any domain — required because the website is hosted on a different origin (S3) than the API.
- `body` must be a **string**, so `json.dumps()` converts the dict to a JSON string.

---

```python
    except ClientError as e:
        print(f"DynamoDB error: {e.response['Error']['Message']}")
        return {
            "statusCode": 500,
            ...
        }
```

- `print()` writes to **CloudWatch Logs** automatically — no extra setup needed.
- Returning `500` instead of crashing ensures the browser receives a proper error response instead of a timeout.

---

## website/script.js

```javascript
const API_URL = "https://YOUR_API_GATEWAY_URL/prod/count";
```

Replace this placeholder with the **Invoke URL** copied from the API Gateway console after deployment.

---

```javascript
async function fetchVisitorCount() {
  const countEl = document.getElementById("visitor-count");
  const btn = document.getElementById("refresh-btn");

  countEl.textContent = "...";
  countEl.className = "counter loading";
  btn.disabled = true;
```

- Sets the counter display to `"..."` and adds a CSS `loading` class (triggers a pulse animation) while the request is in flight.
- Disables the Refresh button to prevent duplicate clicks.

---

```javascript
  const response = await fetch(API_URL, { method: "GET" });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  const data = await response.json();
  countEl.textContent = data.visitorCount.toLocaleString();
```

- `fetch` makes the HTTP GET request to API Gateway.
- `response.ok` is `true` for 2xx status codes; any other code throws an error.
- `toLocaleString()` formats large numbers with commas (e.g. `1,245`).

---

```javascript
  } catch (err) {
    countEl.textContent = "Error";
    countEl.className = "counter error";
  } finally {
    btn.disabled = false;
  }
```

- `catch` shows `"Error"` in red if the API call fails (network down, Lambda error, etc.).
- `finally` **always** re-enables the button, even if an error occurred.

---

```javascript
document.addEventListener("DOMContentLoaded", fetchVisitorCount);
```

Calls `fetchVisitorCount` automatically when the page finishes loading, so the count appears immediately without the user needing to click Refresh.

---

## website/index.html

```html
<span id="visitor-count" class="counter">...</span>
```

- The `id="visitor-count"` is the DOM target that `script.js` updates with the live count.
- Initial text `"..."` is shown before the API responds.

---

## website/style.css

```css
.counter.loading {
  animation: pulse 1.2s ease-in-out infinite;
}
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.3; }
}
```

A subtle **fade in/out** animation plays on the counter while waiting for the API, giving the user a visual indicator that data is loading.

```css
.counter-wrapper {
  background: linear-gradient(135deg, #e94560, #0f3460);
}
```

The counter box uses a **CSS gradient** — no images needed — keeping the website fast to load from S3.

---

# Skills Covered

* Static website hosting on S3
* AWS Lambda development
* API Gateway integration
* DynamoDB CRUD operations
* IAM roles and least-privilege access
* CloudWatch logging
* JavaScript Fetch API
* Serverless application architecture

---

# Possible Enhancements

* Add a **Reset Counter** button (admin only).
* Display **Today's Visitors** and **Total Visitors** separately.
* Show the **Last Visit Time**.
* Capture visitor metadata such as country or browser (respecting privacy).
* Use a custom domain with HTTPS via **CloudFront** and **Route 53**.
* Build a dashboard with charts using **Amazon CloudWatch** or a frontend framework like React.

---

# Interview Questions

1. Why use DynamoDB instead of S3 to store the count?
2. What is the purpose of `UpdateExpression` in DynamoDB?
3. Why is `ADD` preferred for incrementing counters?
4. How does API Gateway invoke Lambda?
5. Why is CORS required?
6. What IAM permissions does the Lambda function need?
7. What happens if two users refresh the page simultaneously?
8. How does DynamoDB ensure atomic counter updates?
9. How would you prevent abuse of the API?
10. How would you scale this application to millions of requests per day?

This project is excellent for learning core serverless concepts and is a common portfolio project because it combines frontend, backend, API, and database components in a simple, production-style architecture.

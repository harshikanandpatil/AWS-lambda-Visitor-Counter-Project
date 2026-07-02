import json
import boto3
import os
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("TABLE_NAME", "visitor-counter")


def lambda_handler(event, context):
    table = dynamodb.Table(TABLE_NAME)

    try:
        response = table.update_item(
            Key={"id": "visitor_count"},
            UpdateExpression="ADD #count :increment",
            ExpressionAttributeNames={"#count": "count"},
            ExpressionAttributeValues={":increment": 1},
            ReturnValues="UPDATED_NEW",
        )

        count = int(response["Attributes"]["count"])

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

    except ClientError as e:
        print(f"DynamoDB error: {e.response['Error']['Message']}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json",
            },
            "body": json.dumps({"error": "Failed to update visitor count"}),
        }

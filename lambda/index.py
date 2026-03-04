import json
import os


def handler(event, context):
    environment = os.environ.get("ENV", "unknown")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello from newsletter lambda",
            "environment": environment,
        }),
    }

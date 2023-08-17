
import os

def hello_lambda_handler(event, context):
    print(event)
    return {
        'statusCode': 200,
        'body': str(event)
    }


import json
import os

# Read the value of the environment variable named 'MY_ENV_VAR'
name = os.environ.get('VAR_NAME')

def handler(event, context):
    print(f"Received Event: {json.dumps(event)}")
    return {
        'statusCode': 200,
        'body': f"Hello {name}, from Lambda!"
    }
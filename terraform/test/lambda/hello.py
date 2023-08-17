# from utils import my_util_function

def lambda_handler(event, context):
    print(event)
    return {
        'statusCode': 200,
        'body': str(event)
    }

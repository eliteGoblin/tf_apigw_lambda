import boto3

def lambda_handler(event, context):
    client = boto3.client('ecs')

    # Fetch subnet and security group info from environment variables
    # subnets = os.environ['SUBNETS'].split(',')
    subnets = ["172.31.0.0/20"]

    response = client.run_task(
        cluster='my-cluster',
        launchType='FARGATE',
        taskDefinition='my-task',
        networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': subnets,
                'assignPublicIp': 'ENABLED'
            }
        }
    )

    print(response)

    return {
        'statusCode': 200,
        'body': str(response)
    }

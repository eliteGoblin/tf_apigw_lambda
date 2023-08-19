#!/usr/bin/env python
from constructs import Construct
from cdktf import App, NamedRemoteWorkspace, TerraformStack, TerraformOutput, RemoteBackend
from cdktf_cdktf_provider_aws.provider import AwsProvider
from cdktf_cdktf_provider_aws.instance import Instance

from constructs import Construct
from cdktf import App, TerraformStack, TerraformAsset, AssetType
from cdktf_cdktf_provider_aws.iam_role import IamRole
from cdktf_cdktf_provider_aws.iam_policy import IamPolicy
from cdktf_cdktf_provider_aws.iam_policy_attachment import IamPolicyAttachment
from cdktf_cdktf_provider_aws.lambda_function import LambdaFunction, LambdaFunctionEnvironment

region = "ap-southeast-2"


class MyTerraformStack(TerraformStack):
    def __init__(self, scope: Construct, ns: str):
        super().__init__(scope, ns)

        import os
        cwd = os.getcwd()

        # Define the AWS provider
        AwsProvider(self, 'Aws', region=region)  # Change the region as needed

        # IAM Role for Lambda
        lambda_execution_role = IamRole(
            self, 'cdktf-LambdaExecutionRole',
            name="cdktf-lambdaExecutionRole",
            assume_role_policy="""{
              "Version": "2012-10-17",
              "Statement": [{
                "Effect": "Allow",
                "Principal": {
                  "Service": "lambda.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
              }]
            }"""
        )

        # IAM Role Policy for Lambda
        lambda_execution_policy = IamPolicy(
            self, 'cdktf-LambdaExecutionRolePolicy',
            name="cdktf-lambdaExecutionRolePolicy",
            policy="""{
                "Version": "2012-10-17",
                "Statement": [{
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Effect": "Allow",
                    "Resource": "*"
                }]
            }""",
        )

        IamPolicyAttachment(
            self, 'cdktf-AttachLambdaExecutionRolePolicy',
            name="YourDesiredNameForAttachment",  # you can specify a name
            policy_arn=lambda_execution_policy.arn,
            roles=[lambda_execution_role.id]
        )

        lambda_asset = TerraformAsset(self, 'LambdaAsset',
            path='./lambda',
            type=AssetType.ARCHIVE,
        )

        # Lambda Function
        lambda_function = LambdaFunction(
            self, 'cdktf-MyLambdaFunction',
            function_name="cdktf-github_event_handler",
            handler="handler.handler",
            runtime="python3.8",
            role=lambda_execution_role.arn,
            # filename=os.path.join(os.getcwd(), 'lambda.zip'),
            filename=lambda_asset.path,
            # filename="/home/fsun/git_repo/tfcdk_playground/tf_apigw_lambda/cdktf/lambda.zip",  # Path to your local directory containing Lambda code
            environment=LambdaFunctionEnvironment(variables={
                "VAR_NAME": "Frank"
            })
        )
        # Outputs
        TerraformOutput(self, 'cdktf-LambdaFunctionArn', value=lambda_function.arn)


class MyStack(TerraformStack):
    def __init__(self, scope: Construct, id: str):
        super().__init__(scope, id)

        # define resources here


app = App()
# MyStack(app, "cdktf")
MyTerraformStack(app, "githubevent_serverless")

app.synth()

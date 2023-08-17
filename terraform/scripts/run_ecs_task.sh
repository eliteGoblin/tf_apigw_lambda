#!/bin/bash

aws ecs run-task --cluster my-cluster \
    --task-definition my-task \
    --count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[\"subnet-02858365\"],assignPublicIp=ENABLED}"

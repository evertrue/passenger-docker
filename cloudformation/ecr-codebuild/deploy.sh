#!/bin/bash

echo -n "Enter ToolsAccount ProfileName for AWS Cli operations [evertruetools] > "
read ToolsAccountProfile

ToolsAccountProfile=${ToolsAccountProfile:-evertruetools}

StackName=passenger-docker-build
ECRBaseRepositoryName=evertrue/passenger
GitHubProjectName=passenger

aws cloudformation deploy --stack-name $StackName --template-file ecr-codebuild.yaml --parameter-overrides ECRBaseRepositoryName=$ECRBaseRepositoryName GitHubProjectName=$GitHubProjectName --profile $ToolsAccountProfile

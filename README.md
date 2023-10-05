# AWS Lambda for Pull Request Automation

This Terraform module creates an AWS Lambda function that automates the process of managing pull requests in AWS CodeCommit. When a pull request is created in a specified branch, the Lambda function updates the title of the original pull request and creates a new pull request targeting the master branch.

## Usage

```hcl
module "pr_automation" {
  source = "path-to-module"

  repository_names = ["repo1", "repo2"]
  staging_branch   = "staging"
  master_branch    = "master"
  identifier       = "myapp"
}
```

## Variables

* **`repository_names (required)`**: A list of CodeCommit repository names.
* **`staging_branch (optional)`**: The name of the staging branch. Default is "staging".
* **`master_branch (optional)`**: The name of the master branch. Default is "master".
* **`identifier (optional)`**: A unique identifier to prepend to resource names. Default is an empty string.
* **`log_retention_in_days (optional)`**: The number of days to retain log events in the specified log group. Default is 14.

## Outputs

* **`lambda_function_name`**: The name of the created Lambda function.
* **`cloudwatch_event_rule_name`**: The name of the CloudWatch Event Rule.
* **`log_group_name`**: The name of the CloudWatch Log Group.

## Lambda Function Code

Below is the Python code for the AWS Lambda function:

```python
import boto3
import json
import os

def handler(event, context):
    staging_branch = os.environ.get('STAGING_BRANCH')
    master_branch = os.environ.get('MASTER_BRANCH')

    detail = event['detail']
    pr_id = detail['pullRequestId']
    pr_title = detail['title']
    repository_name = detail['repositoryNames'][0]
    source_branch = detail['sourceReference']

    client = boto3.client('codecommit')

    try:
        # Update the title of the original PR created for staging
        updated_title = f'[To {staging_branch}] {pr_title}'
        client.update_pull_request_title(
            pullRequestId=pr_id,
            title=updated_title
        )
        print(f"Original PR title updated: {updated_title}")

        # Create a new PR for master
        response = client.create_pull_request(
            title= f'[To {master_branch}] {pr_title}',
            description='Automated PR from feature to master',
            targets=[
                {
                    'repositoryName': repository_name,
                    'sourceReference': source_branch,
                    'destinationReference': 'master',
                },
            ]
        )
        print("PR Created: ", response)
    except Exception as e:
        print("Error creating PR: ", str(e))
```

Ensure the Lambda function code is placed in the same directory as your Terraform configuration and zipped into an archive named create_pr.zip.

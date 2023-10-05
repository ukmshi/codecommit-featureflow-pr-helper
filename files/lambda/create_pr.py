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
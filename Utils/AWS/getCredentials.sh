#!/bin/bash
ROOT_DIR=$(dirname $(dirname $(realpath $0)))
if [ -f "$ROOT_DIR/.env.AWS" ]; then
    source "$ROOT_DIR/.env.AWS"
else
    echo "The .env.AWS file does not exist. Please create the .env.AWS file and try again."
    exit 1
fi
# This script is used to export AWS SSO credentials to the environment variables
# This is useful when you have multiple AWS profiles and you want to switch between them

# TODO: Set a default profile in .env.AWS
# Use a default profile if no profile is provided, or call ./AWS/getCredentials.sh <profile> to specify a profile
profile=${1:-"$DEFAULT_PROFILE"}

AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile $profile)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile $profile)
AWS_SESSION_TOKEN=$(aws configure get aws_session_token --profile $profile)

echo "AWS_ACCESS_KEY_ID: '$AWS_ACCESS_KEY_ID'"
echo "AWS_SECRET_ACCESS_KEY: '$AWS_SECRET_ACCESS_KEY'"
echo "AWS_SESSION_TOKEN: '$AWS_SESSION_TOKEN'"

echo "Successfully exported AWS credentials"

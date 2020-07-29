#!/bin/bash -

rotate() {
    NEW_KEY=$(2>&- aws --output json iam create-access-key --query AccessKey)
    if [ "${NEW_KEY}" == "" ]; then
	echo "failed"
	return
    fi

    ACCESS_KEY_ID=$(echo ${NEW_KEY} | jq -r '.AccessKeyId')
    SECRET_ACCESS_KEY=$(echo ${NEW_KEY} | jq -r '.SecretAccessKey')

    aws iam delete-access-key --access-key-id ${OLD_KEY}

    aws configure set aws_access_key_id ${ACCESS_KEY_ID}
    aws configure set aws_secret_access_key ${SECRET_ACCESS_KEY}

    echo ${ACCESS_KEY_ID}
}

for AWS_PROFILE in ${*:-$(aws configure list-profiles)}; do
    echo $AWS_PROFILE

    OLD_KEY=$(aws configure get aws_access_key_id)

    if [ "${OLD_KEY}" != "" ] && [ "$(aws configure get aws_session_token)" == "" ]; then
	echo -n "Rotating ${AWS_PROFILE}: ${OLD_KEY} - "
	rotate
    fi
done

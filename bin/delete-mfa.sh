#!/bin/bash -

MFA=$(aws --output json iam list-mfa-devices)
[ "${MFA}" == "" ] && exit

SerialNumber=$(echo ${MFA} | jq -r '.MFADevices[].SerialNumber')
UserName=$(echo ${MFA} | jq -r '.MFADevices[].UserName')

aws iam deactivate-mfa-device --user-name "${UserName}" --serial-number "${SerialNumber}"
aws iam delete-virtual-mfa-device --serial-number "${SerialNumber}"

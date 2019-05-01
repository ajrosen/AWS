#!/bin/bash -

export AWS_PROFILE=${AWS_PROFILE:-"default"}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-east-1"}
export AWS_DEFAULT_OUTPUT=text

DOMAIN=${1:?Must specify domain}

BASE=OpenVPN


##################################################
# Delete instance

for x in instance; do
    aws lightsail delete-${x} --${x}-name ${BASE}-Server
done


##################################################
# Delete disk and snapshot
for x in disk disk-snapshot; do
    aws lightsail delete-${x} --${x}-name ${BASE}-PKI
done


##################################################
# Delete domain entry and static IP address

for x in static-ip; do
    STATIC_IP_ADDRESS=`aws --query staticIp.ipAddress lightsail get-static-ip --static-ip-name ${BASE}-IP`

    aws lightsail delete-domain-entry --domain-name ${DOMAIN} --domain-entry name=${AWS_DEFAULT_REGION}.${DOMAIN},target=${STATIC_IP_ADDRESS},type=A
    aws lightsail release-${x} --${x}-name ${BASE}-IP
done

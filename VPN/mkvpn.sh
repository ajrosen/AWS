#!/bin/bash -

##################################################
# Default AWS settings

export AWS_PROFILE=${AWS_PROFILE:-"default"}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-east-1"}
export AWS_DEFAULT_OUTPUT=text

AZ=${AWS_DEFAULT_REGION}a


##################################################
# Default names for AWS resources

BASE=OpenVPN

INSTANCE_NAME=${BASE}-Server
STATIC_IP_NAME=${BASE}-IP
DISK_NAME=${BASE}-PKI


##################################################
# Check command line arguments

DOMAIN=${1:?Must specify domain}

SERVER=vpn.${DOMAIN}
SUB_DOMAIN=ls.${DOMAIN}


##################################################
# Get the blueprint for Amazon Linux (OS Only) and
# the bundle for the least expensive instance

echo "Getting blueprint and bundle"

BLUEPRINT=`aws --query "blueprints[?name=='Amazon Linux'].blueprintId" lightsail get-blueprints --no-include-inactive`
BUNDLE=`aws --query "bundles[?supportedPlatforms[0]=='LINUX_UNIX'] | min_by([], &price).bundleId" lightsail get-bundles --no-include-inactive`


##################################################
# Create a disk and static IP address

echo "Creating disk and static IP address"

1>&- aws lightsail create-disk --disk-name ${DISK_NAME} --availability-zone ${AZ} --size-in-gb 8
1>&- aws lightsail allocate-static-ip --static-ip-name ${STATIC_IP_NAME}

STATIC_IP_ADDRESS=`aws --query staticIp.ipAddress lightsail get-static-ip --static-ip-name ${STATIC_IP_NAME}`


##################################################
# Create the instance

echo "Creating instance"

1>&- aws lightsail create-instances --instance-names ${INSTANCE_NAME} --availability-zone ${AZ} --blueprint-id ${BLUEPRINT} --bundle-id ${BUNDLE} --user-data="`sed "s/^SERVER=.*/SERVER=${SERVER}/" userdata.sh`"

# Wait for instance to be "running"
echo -n "Waiting for instance to start"

while [ 1 ]; do
    STATE=`aws --query state.name lightsail get-instance-state --instance-name ${INSTANCE_NAME}`

    case ${STATE} in
	pending)
	    echo -n "."
	    sleep 2
	    ;;
	running)
	    echo
	    break
	    ;;
	*)
	    echo -e "\nUnknown state: ${STATE}"
	    exit 1
	    ;;
    esac
done


##################################################
# Attach disk and static IP address

echo "Attaching disk and static IP address"

1>&- aws lightsail attach-disk --disk-name ${DISK_NAME} --instance-name ${INSTANCE_NAME} --disk-path /dev/xvdf
1>&- aws lightsail attach-static-ip --static-ip-name ${STATIC_IP_NAME} --instance-name ${INSTANCE_NAME}


##################################################
# Download client configuration files

echo -n "Downloading .ovpn files from ${STATIC_IP_ADDRESS}"

PEM=~/.ssh/LightsailDefaultKey-${AWS_DEFAULT_REGION}.pem

aws --query privateKeyBase64 lightsail download-default-key-pair > ${PEM}
chmod 600 ${PEM}

while [ 1 ]; do
    scp -qri ${PEM} ec2-user@${STATIC_IP_ADDRESS}:/tmp/ovpn .

    if [ $? == 0 ]; then break; fi

    echo -n "."
    sleep 10
done

rm -f ${PEM}


##################################################
# Open OpenVPN port, closing all others

echo "Configuring firewall"

1>&- aws lightsail put-instance-public-ports --port-infos \
     fromPort=1194,toPort=1194,protocol=udp \
     fromPort=443,toPort=443,protocol=tcp \
     --instance-name ${INSTANCE_NAME}


##################################################
# Create a snapshot of the disk volume

echo "Taking snapshot of ${DISK_NAME}"

1>&- aws lightsail create-disk-snapshot --disk-name ${DISK_NAME} --disk-snapshot-name ${DISK_NAME}-snap1


##################################################
# Create domain

echo "Creating domain ${SUB_DOMAIN}"

1>&- aws lightsail create-domain --domain-name ${SUB_DOMAIN}


##################################################
# Create domain entry

echo "Creating domain entry ${AWS_DEFAULT_REGION}.${SUB_DOMAIN}"

1>&- aws lightsail create-domain-entry --domain-name ${SUB_DOMAIN} \
     --domain-entry name=${AWS_DEFAULT_REGION}.${SUB_DOMAIN},target=${STATIC_IP_ADDRESS},type=A


##################################################
# Update DNS

HZ=`aws --query "HostedZones[0].Id" route53 list-hosted-zones-by-name --dns-name ${DOMAIN}`
NS=`aws --query "domain.domainEntries[?type=='NS'].target" lightsail get-domain --domain-name ${SUB_DOMAIN} | fmt -1`

# NS records for ${SUB_DOMAIN}
# CNAME ${SERVER} -> us.${SERVER}
# CNAME us.${SERVER} -> ${AWS_DEFAULT_REGION}.${SUB_DOMAIN}

1>&- aws route53 change-resource-record-sets --hosted-zone-id "${HZ}" --change-batch '{ "Comment": "'${SUB_DOMAIN}'", "Changes": [ { "Action": "UPSERT", "ResourceRecordSet": { "Name": "'${SUB_DOMAIN}'", "Type": "NS", "TTL": 300, "ResourceRecords": [ { "Value": "'${NS}'" } ] } }, { "Action": "UPSERT", "ResourceRecordSet": { "Name": "'${SERVER}'", "Type": "CNAME", "TTL": 300, "ResourceRecords": [ { "Value": "'us.${SERVER}'" } ] } }, { "Action": "UPSERT", "ResourceRecordSet": { "Name": "'us.${SERVER}'", "Type": "CNAME", "TTL": 300, "ResourceRecords": [ { "Value": "'${AWS_DEFAULT_REGION}.${SUB_DOMAIN}' } ] } } ] }'

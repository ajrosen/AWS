#!/bin/bash -

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-east-1"}
export AWS_DEFAULT_OUTPUT=text

AZ=${AWS_DEFAULT_REGION}${1:-"a"}

NAME=OpenVPN
INSTANCE_NAME=${NAME}-Server
STATIC_IP_NAME=${NAME}-IP
DISK_NAME=${NAME}-PKI


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

1>&- aws lightsail create-instances --instance-names ${INSTANCE_NAME} --availability-zone ${AZ} --blueprint-id ${BLUEPRINT} --bundle-id ${BUNDLE} --user-data="`cat userdata.sh`"

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

PEM=/tmp/$$.pem

aws --query privateKeyBase64 lightsail download-default-key-pair > ${PEM}
chmod 400 ${PEM}

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

1>&- aws lightsail put-instance-public-ports --port-infos fromPort=1194,toPort=1194,protocol=udp --instance-name ${INSTANCE_NAME}


##################################################
# Create a snapshot of the disk volume

echo "Taking snapshot of ${DISK_NAME}"

1>&- aws lightsail create-disk-snapshot --disk-name ${DISK_NAME} --disk-snapshot-name ${DISK_NAME}-snap1

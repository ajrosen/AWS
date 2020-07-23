#!/bin/sh -

# Create a VPC with IGW, route table, default route, and private and
# public subnets (in separate availability zones)


##################################################
# Defaults

REGION=us-east-1

NUM_SUBNETS=2

NET_BLOCK=172.17
HOST_BLOCK=0.0
VPC_NETMASK=16

# VPC
CIDR_BLOCK=${NET_BLOCK}.${HOST_BLOCK}/${VPC_NETMASK}
INSTANCE_TENANCY=default

# Subnet
SUBNET_NETMASK=24


##################################################
# Command line options

while [ $# -gt 0 ]; do
    case "${1}" in
	(--region)	REGION=$2;	shift;;
	(--cidr)	NET_BLOCK=$2;	shift;;
	(--subnets)	NUM_SUBNETS=$2;	shift;;
	(--name)	NAME=$2;	shift;;
    esac

    shift
done


##################################################
# Variables

AWS_CLI="aws --region ${REGION} --output text"

AZ=(`${AWS_CLI} ec2 describe-availability-zones | grep -ow "${REGION}[a-z]"`)

if [ ${NUM_SUBNETS} == "max" ]; then NUM_SUBNETS=${#AZ[@]}; fi

# Can't create more subnets than availability zones
if [ ${NUM_SUBNETS} -gt ${#AZ[@]} ]; then
    >&2 echo "Too many subnets (${NUM_SUBNETS}): Only ${#AZ[@]} in ${REGION}"
    NUM_SUBNETS=${#AZ[@]}
fi


##################################################
# Create VPC

echo "Creating VPC"

VPC_ID=`${AWS_CLI} ec2 create-vpc --cidr-block ${CIDR_BLOCK} --instance-tenancy ${INSTANCE_TENANCY} | grep -ow 'vpc-[0-9a-f]*'`
${AWS_CLI} ec2 create-tags --resources ${VPC_ID} --tags Key=Name,Value=${NAME}

${AWS_CLI} ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-support | grep -ow 'vpc-[0-9a-f]*'
${AWS_CLI} ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-hostnames | grep -ow 'vpc-[0-9a-f]*'

echo ${VPC_ID}
echo


##################################################
# Create Internet Gateway

echo "Creating Internet Gateways"

IGW_ID=`${AWS_CLI} ec2 create-internet-gateway | grep -ow 'igw-[0-9a-f]*'`
${AWS_CLI} ec2 create-tags --resources ${IGW_ID} --tags Key=Name,Value=${NAME}


EGW_ID=`${AWS_CLI} ec2 create-egress-only-internet-gateway --vpc-id ${VPC_ID} | grep -ow 'eigw-[0-9a-f]*'`

echo ${IGW_ID} ${EIGW_ID}
echo


##################################################
# Attach Internet Gateway to VPC

echo "Attaching Internet Gateway to VPC"

${AWS_CLI} ec2 attach-internet-gateway --internet-gateway-id ${IGW_ID} --vpc-id ${VPC_ID}

echo


##################################################
# Create Route Tables

echo "Creating Route Tables"

RT_ID_PRV=`${AWS_CLI} ec2 create-route-table --vpc-id ${VPC_ID} | grep -iow 'rtb-[0-9a-f]*'`
${AWS_CLI} ec2 create-tags --resources ${RT_ID_PRV} --tags Key=Name,Value=${NAME}-public

RT_ID_PUB=`${AWS_CLI} ec2 create-route-table --vpc-id ${VPC_ID} | grep -iow 'rtb-[0-9a-f]*'`
${AWS_CLI} ec2 create-tags --resources ${RT_ID_PUB} --tags Key=Name,Value=${NAME}-private

echo ${RT_ID_PRV} ${RT_ID_PUB}
echo


##################################################
# Add default route

echo "Adding default route to public route table"

${AWS_CLI} ec2 create-route --route-table-id ${RT_ID_PUB} --destination-cidr-block 0.0.0.0/0 --gateway-id ${IGW_ID} >/dev/null

echo


##################################################
# Create private subnets

echo "Creating private subnets"

for (( SUBNET=0; ${SUBNET} < ${NUM_SUBNETS}; SUBNET++ )) do
    SUBNET_ID=`${AWS_CLI} ec2 create-subnet --vpc-id ${VPC_ID} --availability-zone ${AZ[${SUBNET}]} --cidr-block ${NET_BLOCK}.${SUBNET}.0/${SUBNET_NETMASK} | grep -ow 'subnet-[0-9a-f]*'`
    ${AWS_CLI} ec2 create-tags --resources ${SUBNET_ID} --tags Key=Name,Value=${NAME}

    # Associate Subnet with Route Table
    ${AWS_CLI} ec2 associate-route-table --subnet-id ${SUBNET_ID} --route-table-id ${RT_ID_PRV} >/dev/null

    echo "${SUBNET_ID} "
done

echo


##################################################
# Create public subnets

echo "Creating public subnets"
    
for (( SUBNET=0; ${SUBNET} < ${NUM_SUBNETS}; SUBNET++ )) do
    SUBNET_ID=`${AWS_CLI} ec2 create-subnet --vpc-id ${VPC_ID} --availability-zone ${AZ[${SUBNET}]} --cidr-block ${NET_BLOCK}.10${SUBNET}.0/${SUBNET_NETMASK} | grep -ow 'subnet-[0-9a-f]*'`
    ${AWS_CLI} ec2 create-tags --resources ${SUBNET_ID} --tags Key=Name,Value=${NAME}

    ${AWS_CLI} ec2 modify-subnet-attribute --subnet-id ${SUBNET_ID} --map-public-ip-on-launch

    # Associate Subnet with Route Table
    ${AWS_CLI} ec2 associate-route-table --subnet-id ${SUBNET_ID} --route-table-id ${RT_ID_PUB} >/dev/null

    echo "${SUBNET_ID} "
done

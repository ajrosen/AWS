#!/bin/bash -

cd /tmp

export AWS_DEFAULT_OUTPUT=text


##################################################
# Get Security Groups that are in use by...

# Instances
aws ec2 describe-instances | grep '^GROUPS' | grep -o 'sg-[0-9a-f]*' > sg-used

# ELBs
aws elb describe-load-balancers | grep '^SECURITYGROUPS' | grep -o 'sg-[0-9a-f]*' >> sg-used

# RDS
aws rds describe-db-instances | grep '^VPCSECURITYGROUPS' | grep -o 'sg-[0-9a-f]*' >> sg-used 


##################################################
# Get all Security Groups

aws ec2 describe-security-groups | grep '^SECURITYGROUPS' | grep -o 'sg-[0-9a-f]*' > sg


##################################################
# Create a space-separated list of Security Groups that are not in use

UNUSED_SG=`grep -v -f sg-used sg | fmt -9999`


##################################################
# Get more detailed information on unused Security Groups

aws ec2 describe-security-groups --group-ids ${UNUSED_SG} | grep '^SECURITYGROUPS'

# Output format is:
#
# SECURITYGROUPS     <Description>        <Security Groupd ID>     <Security Group Name>  <Owner ID>    <VPC ID>


##################################################
# Clean up

rm -f sg-used sg

#!/bin/sh -

###########################################################################
# Enable CloudTrail in all regions.  Command line options let you set the
# name of the CloudTrail, the name and prefix of the S3 bucket, and the
# region that will process global events.
#
# This script is idempotent.  It is recommended that you run this script
# periodically in all accounts, in case a trail is deleted or a new AWS
# region is added.


##################################################
# Options defaults

DEF_NAME=cloudtrail
DEF_BUCKET=mybucket
DEF_PREFIX=cloudtrail
DEF_GLOBAL=us-east-1

NAME=${DEF_NAME}
BUCKET=${DEF_BUCKET}
PREFIX=${DEF_PREFIX}
GLOBAL=${DEF_GLOBAL}


##################################################
# Parse command line options

while [ $# -gt 0 ]; do
    case $1 in
	--help)
	    echo "Usage: $0 [ --name name_of_trail ] [ --bucket s3_bucket ] [ --prefix s3_prefix ] [ --global region ]"
	    echo "Defaults: --name ${DEF_NAME} --bucket ${DEF_BUCKET} --prefix ${DEF_PREFIX} --global ${DEF_GLOBAL}"
	    exit
	    ;;
	--name)
	    shift ; NAME=$1
	    ;;
	--bucket)
	    shift ; BUCKET=$1
	    ;;
	--prefix)
	    shift ; PREFIX=$1
	    ;;
	--global)
	    shift ; GLOBAL=$1
	    ;;
    esac

    shift
done


############################################################
# Get list of regions

REGIONS=`aws --output text ec2 describe-regions | awk '{ print $NF }'`

for REGION in ${REGIONS}; do
    # Set options for trail
    OPTIONS="--name ${NAME} --s3-bucket-name ${BUCKET} --s3-key-prefix ${PREFIX} "

    # Enable global service events only in the "global" region
    if [ "${REGION}" == "${GLOBAL}" ]; then
	OPTIONS="${OPTIONS} --include-global-service-events"
    else
	OPTIONS="${OPTIONS} --no-include-global-service-events"
    fi

    echo "Creating trail in ${REGION}"
    aws --region ${REGION} cloudtrail create-trail ${OPTIONS} > /dev/null
    aws --region ${REGION} cloudtrail start-logging --name ${NAME} > /dev/null
done

# AWS

Scripts, applications, documents, etc. related to Amazon Web Services.

Many scripts are deprecated since the release of AWS Control Tower and the emphasis on IAM Roles over IAM Users. And there is undoubtedly some bitrot. They might still be useful as examples.

## Pricing

Generates CSV files with current pricing data in every region for EC2 and S3, and instance type data for EC2.

## VPN

Documentation and supporting scripts to setup your own VPN server for less than $5/mo.

## mkstack

Merge multiple CloudFormation template files into a single template.

## bin

- assume-role

Configures a CLI profile, using temporary credentials returned by *aws sts assume-role*, for the given account and role.

- aws-configure-profile

Helper script for *aws-mfa*. Configures a CLI profile given an account and existing temporary credentials.

- aws-enable-config

Enables AWS Config in every region.

- aws-enable-flowlogs

Enables VPC Flow Logs in every VPC in every region.

- aws-mfa

Configures a CLI profile, using temporary credentials returned by *aws sts get-session-token*, for IAM users with *Authenticator app* MFA.

- aws-sso

Configures a CLI profile for a login session acquired through AWS SSO.

- delete-mfa

Deactivates and deletes an MFA device.

- enable-cloudtrail

Enables CloudTrail in all regions.

- get-bucket-encryption

Shows the S3 Bucket encryption setting for every bucket.
 
- get-unused-sg

Finds EC2 Security Groups that are not currently used by an EC2 Instances, ELB load balancers, or RDS DB Instances.

- idcperms

Generates a list of every user, group, account, and permission set in IAM Identity Store, in CSV format.

- mkvpc

Creates a VPC, Internet Gateway, S3 endpoint, route tables, default route, public subnets, and private subnets. CIDR block and number of subnets can be given on the command line.

- partitions

Generates a list of every service available in every region for every parition, in JSON format.

- regions

Runs an AWS CLI command in every region, or lists all regions if no command is given.

- rotate-keys

Rotates the IAM access key for every CLI profile if the key is more than 90 days old.

- trigger-schedule

Triggers an EventBridge Schedule.

- trusted-advisor

Generates JSON files with the results and summaries of every Trusted Advisor check. Premium Support is required.

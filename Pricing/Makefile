#!/bin/bash

PRODUCTS=("AmazonS3" "AmazonEC2")

echo "aws ec2 describe-instance-types"
aws ec2 describe-instance-types > instance-types.json
jq -r 'include "AWS/Pricing/EC2Info"; . | @csv "\(cols)", @csv "\(rows)"' instance-types.json | sed 's/\./","/' > instance-types.csv

for PRODUCT in "${PRODUCTS[@]}"; do
    echo "aws pricing get-products --service-code ${PRODUCT} --filters file://${PRODUCT}-filter.json"
    aws pricing get-products --service-code "${PRODUCT}" --filters file://"${PRODUCT}"-filter.json > "${PRODUCT}".json
    jq -r 'include "AWS/Pricing/'"${PRODUCT}"'"; . | @csv "\(cols)", @csv "\(rows)"' "${PRODUCT}".json > "${PRODUCT}".csv
done

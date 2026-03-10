# aws pricing get-products --service-code AmazonEC2 --filters file://ec2.json
#  [ { "Type": "TERM_MATCH", "Field": "productFamily", "Value": "Compute Instance" }
#   ,{ "Type": "TERM_MATCH", "Field": "operatingSystem", "Value": "Linux" }
#   ,{ "Type": "TERM_MATCH", "Field": "preInstalledSw", "Value": "NA" }
#   ,{ "Type": "TERM_MATCH", "Field": "tenancy", "Value": "Shared" } ]
# jq -r 'include "AWS/Pricing/EC2"; . | @csv "\(cols)", @csv "\(rows)"'

def cols: [ "Region", "Instance Type", "Arch", "Cost", "VCpu", "RAM", "Network" ];

def rows:
  .PriceList[] | fromjson

  | .product.attributes as $attrs

  | select($attrs.usagetype | contains("BoxUsage"))
  | select($attrs.regionCode | startswith("cn-") | not)
  | select($attrs.currentGeneration == "Yes")

  | $attrs.regionCode as $region
  | $attrs.instanceType as $type
  | $attrs.physicalProcessor as $arch
  | $attrs.vcpu as $vcpu
  | $attrs.memory as $ram
  | $attrs.networkPerformance as $network
  | .terms.OnDemand[].priceDimensions[].pricePerUnit.USD as $cost

  | [ $region, $type, $arch, ($cost | tonumber), ($vcpu | tonumber), $ram, $network ]

;

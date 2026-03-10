def cols: [ "Region", "Cost", "Class" ]
;

def rows:
  .PriceList[] | fromjson

  # | select(.product.attributes.regionCode | startswith("cn-") | not)
  | select(.product.productFamily == "Storage")

  | .product.attributes as $attrs

  | select($attrs.regionCode | startswith("cn-") | not)

  | $attrs.regionCode as $region
  | .terms.OnDemand[].priceDimensions[].pricePerUnit.USD as $cost
  | $attrs.storageClass as $class

  | [ $region, $cost, $class ]
;

# def region(r): select(.product.attributes.regionCode == r);
# def productFamily(p): select(.product.productFamily == p);
# def storageClass(s): select(.product.attributes.storageClass == s);

# def main(r; c):
#   .PriceList[] | fromjson

#   | region(r)
#   | productFamily("Storage")
#   | storageClass(c)

#   | .product.attributes.storageClass as $c

#   | .terms.OnDemand[].priceDimensions[]
#   | "\($c) \(.pricePerUnit.USD | tonumber) / \(.unit) (\(.description))"

# ;

# def main(r): main(r; "General Purpose");
# def main: main("us-east-1");

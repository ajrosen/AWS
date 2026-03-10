# aws ec2 describe-instance-types
# jq -r 'include "AWS/Pricing/EC2Info"; . | @csv "\(cols)", @csv "\(rows)"'

def cols: ["Family", "Size", "Current", "Arch", "GHz", "Hypervisor", "Free", "Bare", "Cores", "RAM", "Network", "Max ENI", "Storage", "EBS Optimized"];

def rows:
  .InstanceTypes[]

  | .InstanceType as $type
  | .CurrentGeneration as $current
  | .ProcessorInfo.SupportedArchitectures[0] as $arch
  | .ProcessorInfo.SustainedClockSpeedInGhz as $ghz
  | .FreeTierEligible as $free
  | .BareMetal as $bare
  | .VCpuInfo.DefaultCores as $cores
  | .MemoryInfo.SizeInMiB as $ram
  | .NetworkInfo.NetworkPerformance as $network
  | .NetworkInfo.MaximumNetworkInterfaces as $maxeni
  | .InstanceStorageInfo.TotalSizeInGB as $storage
  | .Hypervisor as $hyper
  | .EbsInfo.EbsOptimizedSupport as $ebs

  | [ $type, $current, $arch, $ghz, $hyper, $free, $bare, $cores, $ram, $network, $maxeni, $storage, $ebs ]

;

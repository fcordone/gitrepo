#!/bin/bash

# List all ec2 instances and rds for all accounts in all regions

# REQUIREMENT:
#   install awless
#     https://github.com/wallix/awless

PROFILES="wenance wenance-dev creditosalrio creditosalrio-dev"
REGIONS=$(aws --profile wenance --region us-east-1 ec2 describe-regions | jq -r ".Regions[].RegionName")
OUTPUT="/tmp/ec2_list"

echo -e "\nPiping output to $OUTPUT\n"

for account in $PROFILES
do
  echo -e "  $account\n"
  echo -e "    ec2 instances"
  for region in $REGIONS
  do
    echo -e "\n      $account/$region/ec2"
    awless -p $account -r $region list instances | sed 's/^/        /'
  done
  echo -e "\n    rds instances\n"
  for region in $REGIONS
  do
    echo -e "\n      $account/$region/rds"
    awless -p $account -r $region list databases | sed 's/^/        /'
  done
done | tee $OUTPUT

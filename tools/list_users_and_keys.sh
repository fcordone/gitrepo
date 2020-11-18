#!/bin/bash
# list AWS users for all accounts

#PROFILES="wenance wenance-dev creditosalrio creditosalrio-dev"
PROFILES="wenance"
OUTPUT="/tmp/user_list"

echo -e "\nPiping output to $OUTPUT\n"

for profile in $PROFILES
do
  echo -e "$profile\n"
  USERS=$(aws --profile $profile iam list-users | jq -r ".Users[].UserName")
  for user in $USERS
  do
    echo "$user"
    aws --profile $profile iam list-access-keys --user-name $user | jq -r ".AccessKeyMetadata[].AccessKeyId"
  done
done | tee $OUTPUT

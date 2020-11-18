#!/bin/bash
set -u
#set -e

# Script to create AWS user for all aws accounts and set Developer group

USER=$1
GROUP=Developer
PASS="changeth1sPass"
TEST=0

declare -a AWS_ACCOUNTS=( creditosalrio-dev creditosalrio wenance wenance-dev )

REGION=us-east-1

echo accounts is ${AWS_ACCOUNTS}

for i in "${AWS_ACCOUNTS[@]}"
do
  TEST=$(aws --profile ${i} --region ${REGION} iam get-user --user-name ${USER} |grep UserName |wc -l)
  if [ ${TEST} -eq "0" ]; then
    echo "[INFO]: Create user at ${i}: "
    aws --profile ${i} --region ${REGION} iam create-user --user-name ${USER}

    echo "[INFO]: Set password: "
    aws --profile ${i} --region ${REGION} iam create-login-profile --user-name ${USER} --password ${PASS} --password-reset-required

    echo "[INFO]: Add to group ${GROUP} "
    aws --profile ${i} --region ${REGION} iam add-user-to-group --user-name ${USER} --group-name ${GROUP}
  else
    echo "User ${USER} already exists on account ${i} "
  fi
done

echo ""
echo "User ${USER} created"
echo "Password is: ${PASS} and must be changed"

echo "AWS Console URLs: "
echo "wenance (PROD & STAGE): https://wenance.signin.aws.amazon.com/console"
echo "wenance-dev (DEV): https://wenance-dev.signin.aws.amazon.com/console"
echo "creditosalrio (PROD & STAGE):  https://creditosalrio.signin.aws.amazon.com/console"
echo "creditosalrio-dev (DEV): https://creditosalrio-dev.signin.aws.amazon.com/console"

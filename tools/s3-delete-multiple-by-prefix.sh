#!/bin/bash
set -e
set -u
#use environment & prefix(stack)
#echo -n "Enter the prefix of the S3 Buckets to be deleted? "
echo $(date +%F-%H:%M:%S)
if [ $# == 2 ]
then
    MYENV=$1
    PREFIX=$2
else
    echo "[ERROR]: Usage $0 <env> <prefix>"
  exit 1
fi
MYENV=$1
MYPROFILE=nondefined
MYREGION=us-east-1
case $MYENV in
        "wdev")
          echo "[INFO]: Apply to W DEV..."
          MYPROFILE=wenance-dev
        ;;
        "wstage")
          echo "[INFO]: Apply to W STAGE..."
          MYPROFILE=wenance
        ;;
        "wprod")
          echo "[INFO]: Apply to W PROD..."
          MYPROFILE=wenance
        ;;      
        "cprod")
          echo "[INFO]: Apply to C PROD..."
          MYPROFILE=creditosalrio
        ;;
        "Quit")
          break
        ;;
        *)
          echo "invalid option"
        ;;
    esac        

deleteArr=($(aws s3 --profile ${MYPROFILE} --region ${MYREGION} ls | awk '{ print $3 }' | grep "${PREFIX}"))
#echo "cantidad =${#deleteArr[@]}"
#echo "valores --- ${deleteArr[@]}"
if ${#deleteArr[@]} -eq 0
then
    printf "\n No Buckets to be deleted\n\n"
    echo "No S3 Buckets to delete .... "
    exit 1
fi
printf "\n Buckets to be deleted\n\n"
printf '%s\n' "${deleteArr[@]}"
printf '\n\n'
cat << EOF
1. Delete all buckets at once
Other: Exit
EOF
read choice

if "$choice" != "1"
then
    echo "Exiting ......"
    exit 1
else 
    for each in "${deleteArr[@]}"
  do
    echo "Bucket: $each"
    aws s3api --profile ${MYPROFILE} put-bucket-versioning --bucket ${each} --versioning-configuration Status=Suspended
    echo "Bucket : $each paso 1 ok"
    aws s3api --profile ${MYPROFILE} delete-objects --bucket ${each} --delete "$(aws s3api list-object-versions --profile ${MYPROFILE} --bucket ${each} | jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" 2>/dev/null
    echo "Bucket : $each paso 2 ok"
    aws s3api --profile ${MYPROFILE} delete-objects --bucket ${each} --delete "$(aws s3api list-object-versions --profile ${MYPROFILE} --bucket ${each} | jq '{Objects: [.DeleteMarkers[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"  2>/dev/null
    echo "Bucket : $each paso 3 ok"
    aws s3 --profile ${MYPROFILE} rb s3://${each} --force
    echo "Bucket : $each paso 4 ok"
    echo "Bucket : $each Deleted ok"
  done
fi

# for each in "${deleteArr[@]}"
# do
#   echo "Bucket: $each"
#   if [ "$choice" == "2" ]; then
#       echo -n "Do you confirm (y/n)?"
#       read confirm
#   else
#       confirm=y
#   fi

#if [ "$choice" == "1" ]; then

#fi 

 # if echo "$confirm" | grep -iq "^y" ;then
 #    #aws s3api --profile ${MYPROFILE} put-bucket-versioning --bucket ${each} --versioning-configuration Status=Suspended
 #    #echo "Bucket : $each paso 1 ok"
 #    aws s3api --profile ${MYPROFILE} delete-objects --bucket ${each} --delete "$(aws s3api list-object-versions --profile ${MYPROFILE} --bucket ${each} | jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" 2>/dev/null
 #    echo "Bucket : $each paso 2 ok"
 #    aws s3api --profile ${MYPROFILE} delete-objects --bucket ${each} --delete "$(aws s3api list-object-versions --profile ${MYPROFILE} --bucket ${each} | jq '{Objects: [.DeleteMarkers[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"  2>/dev/null
 #    echo "Bucket : $each paso 3 ok"
 #    aws s3 --profile ${MYPROFILE} rb s3://${each} --force
 #    echo "Bucket : $each paso 4 ok"
 #    echo "Bucket : $each Deleted ok"
 #  fi
#done
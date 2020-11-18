#!/bin/bash
set -e
set -u

if [ $# == 2 ]
then
    MYENV=$1
    APP_NAME=$2
else
    echo "[ERROR]: Usage $0 <env> <app_name>"
	exit 1
fi

# application name must match between folder name and github repo name as:
# dir=application -> github repo: aws-stacks-application
STACK_DIR=../aws-stack-${APP_NAME}
STACK_DEFAULTS=${APP_NAME}/defaults.json

DIR=$(basename $PWD)

if [ ${DIR} == "aws-stacks" ]
then
    echo "[INFO]: scritp dir is: ${DIR}"
else
   echo "[ERROR]: Just run it at aws-stacks dir"
   exit 1
fi

if [ ! -d ${APP_NAME} ]
then
    echo "[ERROR]: application not found"
    exit 1
fi

MYPROFILE=nondefined
MYREGION=us-east-1
STACK_BUCKET=nondefined
TEMPLATE=nondefined
DATE=`date +%Y%m%d-%Hh-%Mm`
STACK_BRANCH=nondefined

#TODO: revisar esto, deberia ser un mapa del script y ya tener los nombres de los stacks actuales
#para evitar subir cualquier cosa
AWS_STACK_DIR=../aws-stack-$APP_NAME/

case $MYENV in
        "wdev")
          echo "[INFO]: Upload to W DEV..."
          MYPROFILE=wenance-dev
        ;;
        "wstage")
          echo "[INFO]: Upload to W STAGE..."
          MYPROFILE=wenance
        ;;
        "wprod")
          echo "[INFO]: Upload to W PROD..."
          MYPROFILE=wenance
        ;;
        "cdev")
          echo "[INFO]: Upload to C DEV..."
          MYPROFILE=creditosalrio-dev
        ;;
        "cstage")
          echo "[INFO]: Upload to C STAGE..."
          MYPROFILE=creditosalrio
        ;;
        "cprod")
          echo "[INFO]: Upload to C PROD..."
          MYPROFILE=creditosalrio
        ;;
        "waprod")
          echo "[INFO]: Upload to Whatsapp Prod..."
          MYPROFILE=wenance-whatsapp
        ;;
        "Quit")
          break
        ;;
        *)
          echo "invalid option"
        ;;
    esac


# load legacy names:
STACK_BUCKET=stack-$APP_NAME-${MYENV}
if [ -f ${STACK_DEFAULTS} ]
then
    STACK_NAME="$( jq -r ".${MYENV}[].STACK_NAME" "${STACK_DEFAULTS}" )"
    echo "[INFO]: Using STACK_NAME from defaults as: ${STACK_NAME}"
else
    STACK_NAME=$APP_NAME-${MYENV}
fi


#check bucket
if aws --profile ${MYPROFILE} s3 ls "s3://${STACK_BUCKET}" 2>&1 | grep -q 'An error occurred'
then
  #TODO: create the bucket
  read -p "[INFO]: Bucket ${STACK_BUCKET} does not exists, do you want to create it [yN]? " -n 1 -r
  echo # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "[INFO]: Cancel"
    exit 1
  else
    echo "[INFO]: Creating .... "
    aws --region ${MYREGION} --profile ${MYPROFILE} s3 mb s3://${STACK_BUCKET}
    echo "[INFO]: Enabling Versioning ...."
    aws --region ${MYREGION} --profile ${MYPROFILE} s3api put-bucket-versioning --bucket ${STACK_BUCKET} --versioning-configuration Status=Enabled
  echo "[INFO]: for existing applications delete old bucket !!!!!!!!!!!!!!!!!!!"
  fi
else
  echo "[INFO]: Bucket Exists: ${STACK_BUCKET}"
fi

  if [[ -d ${STACK_DIR} ]]
  then
    STACK_BRANCH=`cd ${STACK_DIR} && echo -e "\n $(git branch --list)" && cd - 2>&1 >> /dev/null`
      read -p "[INFO]: Upload ${STACK_DIR} branch ${STACK_BRANCH}, continue [yN]? " -n 1 -r
      echo # (optional) move to a new line
      if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo "[INFO]: Cancel"
        exit 1
      else
          echo "[INFO]: Upload ${STACK_DIR} yaml files ..."
          aws --region ${MYREGION} --profile ${MYPROFILE} s3 cp ${STACK_DIR} s3://${STACK_BUCKET} --recursive --exclude "*" --include "*.yaml"
          #copy zip
          #aws --region ${MYREGION} --profile ${MYPROFILE} s3 cp *.zip s3://${STACK_BUCKET}
      fi
  fi
  echo "[INFO]: Upload all yaml files at ${APP_NAME} dir ... "
  #copy all yaml
  echo "[INFO]: Upload aws-stacks/${APP_NAME} yaml files ..."
  aws --region ${MYREGION} --profile ${MYPROFILE} s3 cp ${APP_NAME} s3://${STACK_BUCKET} --recursive --exclude "*" --include "*.yaml"

  #upload templates from cfn-templates dir used on this project main.yaml
  echo "[INFO]: Check & upload real templates usage from cfn-templates dir ..."
  for i in `grep "cfn-templates/" ${APP_NAME}/main.yaml | awk -F/ '{print $NF}' | sort -u`
  do
    aws --region ${MYREGION} --profile ${MYPROFILE} s3 cp cfn-templates/$i s3://${STACK_BUCKET}/cfn-templates/
  done

  echo "[INFO]: Use bucket $STACK_BUCKET"
  TEMPLATE=https://s3.amazonaws.com/${STACK_BUCKET}/main.yaml
  echo "[INFO]: Template Bucket is ${TEMPLATE}"
  #if stack not exists,create
  if aws cloudformation --profile ${MYPROFILE} --region ${MYREGION} describe-stacks --stack-name ${STACK_NAME} 2>&1 | grep -q 'An error occurred'
  then
      read -p "[INFO]: Stack ${STACK_NAME} does not exist, do you want to create it [yN]? " -n 1 -r
      echo # (optional) move to a new line
      if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo "[INFO]: Cancel"
        exit 1
      else
        echo "[INFO]: Creating .... "
        aws cloudformation create-stack  \
        --profile ${MYPROFILE} \
        --region ${MYREGION} \
        --stack-name ${STACK_NAME} \
        --template-url ${TEMPLATE} \
        --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
        --parameters file://./${APP_NAME}/${MYENV}-parameters.json
        echo "[INFO]: Waiting for stack to be created ..."
        aws cloudformation wait stack-create-complete \
        --profile ${MYPROFILE} \
        --region ${MYREGION} \
        --stack-name ${STACK_NAME}

      fi
    #if stack exists create change-set
  else
      echo -e "\n[INFO]:Stack exists,Creating changeset..."
      aws cloudformation create-change-set \
      --change-set-name "DeployFromAwsStacksScript-${DATE}" \
      --profile ${MYPROFILE} \
      --region ${MYREGION} \
      --stack-name ${STACK_NAME} \
      --template-url ${TEMPLATE} \
      --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
      --parameters file://./${APP_NAME}/${MYENV}-parameters.json
      echo "[INFO]: Waiting for changeset to be created ..."
      aws cloudformation wait change-set-create-complete \
      --profile ${MYPROFILE} \
      --region ${MYREGION} \
      --stack-name ${STACK_NAME} \
      --change-set-name "DeployFromAwsStacksScript-${DATE}"

fi

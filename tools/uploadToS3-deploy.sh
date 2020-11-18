#/bin/bash
set -e
set -u

MYENV=$1

MYPROFILE=nondefined
MYREGION=us-east-1
STACK_BUCKET=nondefined
TEMPLATE=nondefined
ENV=nondefined
ACCOUNT_NAME=nondefined # not AWS account anymore, its vpc mapping
TOOLS_VPN_SG=sg-03a036ac3f577d3e1
TransitGatewayID=tgw-0832185209d2450f4

DATE=`date +%Y%m%d-%Hh-%Mm`

case $MYENV in
        "wdev")
            echo "[INFO]: Upload to DEV..."
  	    MYPROFILE=wenance-dev
  	    ACCOUNT_NAME=wenance-dev
            STACK_BUCKET=stack-master-vpc-dev
	    MASTER_STACK=master-vpc
	    ENV=dev
            ;;
        "wstage")
            echo "[INFO]: Upload to STAGE..."
  	    MYPROFILE=wenance
  	    ACCOUNT_NAME=wenance-stage
            STACK_BUCKET=stack-master-vpc-stage
	    MASTER_STACK=master-vpc-stage
	    ENV=stage
            ;;
        "wprod")
            echo "[INFO]: Upload to PROD..."
  	    MYPROFILE=wenance
  	    ACCOUNT_NAME=wenance
            STACK_BUCKET=stack-master-vpc-prod
	    MASTER_STACK=master-vpc
	    ENV=prod
            ;;
        "cdev")
            echo "[INFO]: Upload to C DEV..."
  	    MYPROFILE=creditosalrio-dev
  	    ACCOUNT_NAME=creditosalrio-dev
            STACK_BUCKET=stack-master-vpc-cdev
	    MASTER_STACK=master-vpc
	    ENV=dev
            ;;
        "cstage")
            echo "[INFO]: Upload to C STAGE..."
  	    MYPROFILE=creditosalrio
  	    ACCOUNT_NAME=creditosalrio-stage
            STACK_BUCKET=stack-master-vpc-cstage
	    MASTER_STACK=master-vpc-stage
	    ENV=stage
            ;;
        "cprod")
            echo "[INFO]: Upload to C PROD..."
  	    MYPROFILE=creditosalrio
  	    ACCOUNT_NAME=creditosalrio
            STACK_BUCKET=stack-master-vpc-cprod
	    MASTER_STACK=master-vpc
	    ENV=prod
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac

#check bucket
if aws --profile ${MYPROFILE} s3 ls "s3://${STACK_BUCKET}" 2>&1 | grep -q 'An error occurred'
then
  #TODO: create the bucket
  echo "[ERROR]: Bucket ${STACK_BUCKET} does not exit or permission is not there to view it."
  exit 1
else
  #copy all yaml
  aws --region ${MYREGION} --profile ${MYPROFILE} s3 cp . s3://${STACK_BUCKET} --recursive --exclude "*" --include "*.yaml"

  echo "[INFO]: Use bucket $STACK_BUCKET"
  TEMPLATE=https://s3.amazonaws.com/${STACK_BUCKET}/vpc.yaml
  echo "[INFO]: Template Bucket is ${TEMPLATE}"

  echo "[INFO]: Create changeset ..."

  aws cloudformation create-change-set \
  --change-set-name "DeployFromGitHub-${DATE}" \
  --profile ${MYPROFILE} \
  --region ${MYREGION} \
  --stack-name ${MASTER_STACK} \
  --template-url ${TEMPLATE} \
  --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
  --parameters \
  ParameterKey=AccountName,ParameterValue=${ACCOUNT_NAME} \
  ParameterKey=Environment,ParameterValue=${ENV} \
  ParameterKey=TopicMail,ParameterValue=devops@wenance.com \
  ParameterKey=TemplateBucket,ParameterValue=${STACK_BUCKET} \
  ParameterKey=ToolsVpnSG,ParameterValue=${TOOLS_VPN_SG} \
  ParameterKey=TransitGatewayID,ParameterValue=${TransitGatewayID}

fi

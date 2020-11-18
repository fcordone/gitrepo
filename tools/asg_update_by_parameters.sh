#!/bin/bash
set -e
set -u

echo $(date +%F-%H:%M:%S)
MYENV=$1
STACK=$2

MYPROFILE=nondefined
MYREGION=us-east-1

case $MYENV in
        "wdev")
            echo "[INFO]: wenance-dev ..."
            MYPROFILE=wenance-dev
            ENV=dev
            ;;
        "wstage")
            echo "[INFO]: wenance ..."
            MYPROFILE=wenance
            ENV=stage
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac

LIST_ASG=`aws --profile ${MYPROFILE} --region ${MYREGION} autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='ENV') && Value=='${ENV}']] | [? Tags[? Key=='APP' && Value =='${STACK}']].AutoScalingGroupName" --output text´


# for i in $LIST_ASG
# do
# 	aws --profile ${MYPROFILE} --region ${MYREGION} autoscaling update-auto-scaling-group --auto-scaling-group-name $i --min-size $MIN --max-size $MAX --desired-capacity $DESIRED
# done

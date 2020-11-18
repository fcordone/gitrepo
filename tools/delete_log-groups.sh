#!/bin/bash
set -e
set -u

echo $(date +%F-%H:%M:%S)
MYENV=$1

case $MYENV in
        "cprod")
            echo "[INFO]: creditosalrio ..."
            MYPROFILE=creditosalrio
           ;;
        "wdev")
            echo "[INFO]: wenance-dev ..."
            MYPROFILE=wenance-dev
            ;;
        "wstage")
            echo "[INFO]: wenance ..."
            MYPROFILE=wenance
            ;;
        "wprod")
            echo "[INFO]: wenance ..."
            MYPROFILE=wenance
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac

echo "[INFO]: Getting log-group-names..."
LOG_GROUPS=($(aws --profile=$MYPROFILE logs describe-log-groups | jq -r '.logGroups[].logGroupName'))
if [ ${#LOG_GROUPS[@]} -eq 0 ]
 then
     printf "\n No LOG_GROUPS to be deleted\n\n"
     exit 1
fi
printf "\n LOG GROUPS to be deleted\n\n"
printf '%s\n' "${LOG_GROUPS[@]}"
printf '\n'

echo "These Log Groups will be deleted:"

read -p "[INFO]:  Delete all Cloudwatch LOG Groups [yN]? " -n 1 -r

if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "[INFO]: Cancel"
        exit 1
    else

        for name in ${LOG_GROUPS}; 
        do
            printf "\n Delete Log Groups ${name}... "
            aws --profile=$MYPROFILE logs delete-log-group --log-group-name ${name} && echo OK || echo Fail
        done
fi
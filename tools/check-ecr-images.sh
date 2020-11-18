#!/bin/bash
set -e
set -u

echo $(date +%F-%H:%M:%S)
MYENV=$1

MYPROFILE=nondefined
MYREGION=us-east-1

case $MYENV in
        "cdev")
            echo "[INFO]: creditosalrio-dev ..."
            MYPROFILE=creditosalrio-dev
            ;;
        "cstage")
            echo "[INFO]: creditosalrio ..."
            MYPROFILE=creditosalrio
            ;;
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
        "wprodohio")
            echo "[INFO]: wenance Ohio..."
            MYPROFILE=wenance
            MYREGION=us-east-2
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac

echo "[INFO]: ${MYENV} "

repositories=`aws --profile ${MYPROFILE} --region ${MYREGION}  ecr describe-repositories | jq .repositories[].repositoryName -r`

repositoriescount=`echo ${repositories} | wc -l`
#services=`echo ${servicesraw} | jq '.serviceArns[]' -ar | cut -d'/' -f2 `
echo "Repositories : "
echo "${repositories}"
echo "----"
echo "Service Count : ${repositoriescount}"
echo "----"
TotalImagenes=0
for i in ${repositories}
do
  #slog=`echo ${i} | awk -F'-' '{print $1"-"$2"-"$3}'`
  echo "${i}"
  #echo "do something right $i"
  imagecount=`aws --profile ${MYPROFILE} --region ${MYREGION} ecr list-images --repository-name ${i} | jq '.imageIds[].imageDigest' | wc -l`

  echo "${imagecount}"
  TotalImagenes=$((TotalImagenes+imagecount))
done
echo "----"
echo "TotalImagenes Count : ${TotalImagenes}"
echo "----"

#aws --profile ${MYPROFILE} --region ${MYREGION}  ecs list-services --cluster ${MYCLUSTER} | jq '.serviceArns[]' -ar | cut -d'/' -f2 | xargs aws --profile ${MYPROFILE} --region ${MYREGION} ecs describe-services --cluster ${MYCLUSTER} --service {} | jq '.services[].events[0].message' | grep "steady state"

#e {} | jq '.services[].events[0].message' | grep "steady state"

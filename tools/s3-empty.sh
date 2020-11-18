#/bin/bash
for bucket in $(aws s3 ls | awk '{print $3}' | grep prod-onboarding-codepipeline); do  aws s3 rm "s3://${bucket}" --recursive ; done
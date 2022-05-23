#!/bin/bash

source ./utils.sh

# ---------------------------------------------------------------------------------------------------------------------
# SetUp
# ---------------------------------------------------------------------------------------------------------------------

infoln "increase the disk area"

pip3 install --user --upgrade boto3
export instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
python -c "import boto3
import os
from botocore.exceptions import ClientError 
ec2 = boto3.client('ec2')
volume_info = ec2.describe_volumes(
    Filters=[
        {
            'Name': 'attachment.instance-id',
            'Values': [
                os.getenv('instance_id')
            ]
        }
    ]
)
volume_id = volume_info['Volumes'][0]['VolumeId']
try:
    resize = ec2.modify_volume(    
            VolumeId=volume_id,    
            Size=30
    )
    print(resize)
except ClientError as e:
    if e.response['Error']['Code'] == 'InvalidParameterValue':
        print('ERROR MESSAGE: {}'.format(e))"
if [ $? -eq 0 ]; then
    sudo reboot
fi

infoln "Install kubernetes tools"

sudo curl --silent --location -o /usr/local/bin/kubectl \
   https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl

sudo chmod +x /usr/local/bin/kubectl

infoln "update awscli"

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

infoln "Install jq, envsubst (from GNU gettext utilities) and bash-completion"

sudo yum -y install jq gettext bash-completion moreutils

infoln "Install yq for yaml processing"

echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}' | tee -a ~/.bashrc && source ~/.bashrc

infoln "Verify the binaries are in the path and executable"

for command in kubectl jq envsubst aws
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done

infoln "Enable kubectl bash_completion"

kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

infoln "set the AWS Load Balancer Controller version"

echo 'export LBC_VERSION="v2.4.1"' >>  ~/.bash_profile
echo 'export LBC_CHART_VERSION="1.4.1"' >>  ~/.bash_profile
.  ~/.bash_profile

# ---------------------------------------------------------------------------------------------------------------------
# Udate IAM setting 
# ---------------------------------------------------------------------------------------------------------------------

infoln "disable temporary credentials"

aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials

infoln "configure CLI with the current Region "

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text --region $AWS_REGION))

infoln "check the desired resgion"

test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set

infoln "save to the bash_profile"
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
echo "export AZS=(${AZS[@]})" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region
source ~/.bash_profile

infoln "validate IAM role"

aws sts get-caller-identity --query Arn | grep eksworkshop-admin -q && echo "IAM role valid" || echo "IAM role NOT valid"


# ---------------------------------------------------------------------------------------------------------------------
# CLONE THE SERVICE REPOS
# ---------------------------------------------------------------------------------------------------------------------

infoln "clone the services repos"

cd ~/environment
git clone https://github.com/aws-containers/ecsdemo-frontend.git
git clone https://github.com/aws-containers/ecsdemo-nodejs.git
git clone https://github.com/aws-containers/ecsdemo-crystal.git

# ---------------------------------------------------------------------------------------------------------------------
# Create KMS
# ---------------------------------------------------------------------------------------------------------------------


infoln "Create a CMK for the EKS cluster to use when encrypting your Kubernetes secrets"

aws kms create-alias --alias-name alias/eksworkshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)

infoln "Retrieve the ARN of the CMK to input into the create cluster command"

export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)

infoln "save the MASTER_ARN environment variable into the bash_profile"

echo "export MASTER_ARN=${MASTER_ARN}" | tee -a ~/.bash_profile
source ~/.bash_profile
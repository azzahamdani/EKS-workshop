#!/bin/bash

source ./utils.sh

infoln "For this module, we need to download the eksctl binary"

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

sudo mv -v /tmp/eksctl /usr/local/bin

infoln "Confirm the eksctl command works:"

eksctl version

infoln "Enable eksctl bash-completion"


eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
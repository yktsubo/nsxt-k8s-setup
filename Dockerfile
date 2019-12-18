FROM ubuntu:16.04
MAINTAINER "yuki"

RUN apt-get update && apt-get install -y \
 gettext \
 build-essential \
 python3 \
 python3-pip \
 curl \
 unzip \
 libffi-dev \
 libssl-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install govc
RUN curl -L https://github.com/vmware/govmomi/releases/download/v0.21.0/govc_linux_amd64.gz | gunzip > /usr/local/bin/govc
RUN chmod +x /usr/local/bin/govc

# Install terraform
RUN curl -O https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_linux_amd64.zip
RUN unzip terraform_0.12.18_linux_amd64.zip -d /usr/local/bin/
RUN chmod +x /usr/local/bin/terraform
RUN rm terraform_0.12.18_linux_amd64.zip

# Install pynsxt
RUN pip3 install paramiko
RUN pip3 install requests

ADD "./nsxt-k8s-setup/" /root/nsxt-k8s-setup/

WORKDIR /root/nsxt-k8s-setup/

# Start init daemon
CMD ["/root/nsxt-k8s-setup/deploy_k8s_on_nsxt.sh"]

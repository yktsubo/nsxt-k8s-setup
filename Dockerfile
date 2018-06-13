FROM ubuntu:16.04
MAINTAINER "yuki"

RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install gettext
RUN apt-get -y install build-essential
RUN apt-get -y install python
RUN apt-get -y install python-pip
RUN apt-get -y install ansible
RUN apt-get -y install sshpass
RUN apt-get -y install vim
RUN apt-get -y install curl
RUN apt-get -y install git
RUN apt-get -y install unzip
RUN apt-get -y install libffi-dev
RUN apt-get -y install libssl-dev
RUN apt-get clean

# Install govc
RUN curl -L https://github.com/vmware/govmomi/releases/download/v0.18.0/govc_linux_amd64.gz | gunzip > /usr/local/bin/govc
RUN chmod +x /usr/local/bin/govc

# Install terraform
RUN curl -O https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
RUN unzip terraform_0.11.7_linux_amd64.zip -d /usr/local/bin/
RUN chmod +x /usr/local/bin/terraform
RUN rm terraform_0.11.7_linux_amd64.zip

# Install pynsxt
RUN pip install pip --upgrade
RUN pip install requests
RUN pip install bravado
RUN pip install paramiko

RUN git clone https://github.com/yktsubo/pynsxt.git

RUN pip install pynsxt/

ADD "./nsxt-k8s-setup/" /root/nsxt-k8s-setup/

WORKDIR /root/nsxt-k8s-setup/

# Start init daemon
CMD ["/root/nsxt-k8s-setup/deploy_k8s_on_nsxt.sh"]

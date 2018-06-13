FROM ubuntu:16.04
MAINTAINER "yuki"

RUN apt-get update && apt-get -y upgrade

RUN apt-get -y install gettext
RUN apt-get -y install python-pip
RUN apt-get -y install ansible
RUN apt-get -y install sshpass
RUN apt-get -y install vim

RUN pip install pip --upgrade
RUN pip install requests
RUN pip install bravado
RUN pip install paramiko

ADD "./nsxt-k8s-setup/" /root/nsxt-k8s-setup/

WORKDIR /root/nsxt-k8s-setup/

# Start init daemon
CMD ["/root/nsxt-k8s-setup/deploy_k8s_on_nsxt.sh"]

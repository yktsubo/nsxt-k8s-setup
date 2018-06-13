#!/bin/bash
# usage
cmdname=`basename $0`
function usage()
{
    echo "Usage: ${cmdname}"  1>&2
}

# Add hosts file
echo "${VCENTER_IP} vc-01a.corp.local" >> /etc/hosts
echo "${NSX_EDGE_01_IP} nsxedge-01a" >> /etc/hosts
echo "${NSX_EDGE_02_IP} nsxedge-02a" >> /etc/hosts
echo "${ESXI_01_IP} esxcomp-01a.corp.local" >> /etc/hosts
echo "${ESXI_02_IP} esxcomp-02a.corp.local" >> /etc/hosts
echo "${NSX_MANAGER_IP} nsxmgr-01a.corp.local" >> /etc/hosts
echo "${NSX_CONTROLLER_01_IP} nsxctrl-01a.corp.local" >> /etc/hosts
echo "${K8S_MASTER_IP} k8s-mater"  >> /etc/hosts
echo "${K8S_NODE1_IP} k8s-node1"  >> /etc/hosts
echo "${K8S_NODE2_IP} k8s-node2"  >> /etc/hosts
echo "${K8S_NODE3_IP} k8s-node2"  >> /etc/hosts

# VARIABLE
cat ./templates/hosts | envsubst > ./hosts
cat ./templates/answerfile.yml | envsubst > ./answerfile.yml
cat ./templates/connect_to_manager.yml  | envsubst > ./pynsxt/connect_to_manager.yml
cat ./templates/prepare_infra.yml | envsubst > ./pynsxt/prepare_infra.yml
cat ./templates/prepare_k8s.yml | envsubst > ./pynsxt/prepare_k8s.yml
cat ./templates/k8s_tag_vif.yml | envsubst > ./pynsxt/k8s_tag_vif.yml
cat ./templates/terraform.tfvars | envsubst > ./terraform/terraform.tfvars
cat ./templates/build.tf | envsubst > ./terraform/build.tf

# Deploy OVF and convert it to template
govc import.ovf "files/ubuntu_ovf/ubuntu.ovf"
govc vm.markastemplate "ubuntu"

# PowerOn VMs
govc vm.power -on 'nsxedge-02a'

echo "Sleep 180 sec to Wait for Edge node becomes up"
sleep 180

# NSX-T configureation
pynsxt -c ./pynsxt/connect_to_manager.yml

echo "Sleep 180 sec to Wait for components ready"
sleep 180

echo "Coniguring NSX-T"

pynsxt -c ./pynsxt/prepare_infra.yml
pynsxt -c ./pynsxt/prepare_k8s.yml

echo "Sleep 300 sec to Wait for components ready..."
sleep 300

# Terraform is used to deploy k8s nodes
echo "Deploying k8s nodes"
cd ./terraform
terraform init
terraform apply -auto-approve
cd ../

# Tag VIF of VM
echo "Tagging k8s nodes VIF"
pynsxt -c ./pynsxt/k8s_tag_vif.yml

# Generate SSH key
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
echo "Host 192.168.*.*" >> ~/.ssh/config 
echo "StrictHostKeyChecking no" >> ~/.ssh/config 
echo "UserKnownHostsFile=/dev/null"  >> ~/.ssh/config 


echo "Sleep 400 sec to Wait for DHCP expired in K8s nodes"
sleep 400

# Install K8s and NCP by ansible
echo "Start configuring  k8s nodes"
ansible-playbook -i ./hosts ./playbooks/deploy_k8s.yml

exit 0


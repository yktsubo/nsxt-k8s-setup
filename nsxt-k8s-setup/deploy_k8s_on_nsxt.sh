#!/bin/bash
# usage
cmdname=`basename $0`
function usage()
{
    echo "Usage: ${cmdname}"  1>&2
}

MAX_RETRY=30

# Add hosts file
echo "${VCENTER_IP} vc-01a.corp.local" >> /etc/hosts
echo "${NSX_EDGE_01_IP} nsxedge-01a" >> /etc/hosts
echo "${NSX_EDGE_02_IP} nsxedge-02a" >> /etc/hosts
echo "${ESXI_01_IP} esxcomp-01a.corp.local" >> /etc/hosts
echo "${ESXI_02_IP} esxcomp-02a.corp.local" >> /etc/hosts
echo "${ESXI_03_IP} esxcomp-03a.corp.local" >> /etc/hosts
echo "${NSX_MANAGER_IP} nsxmgr-01a.corp.local" >> /etc/hosts
echo "${K8S_MASTER_IP} k8s-mater"  >> /etc/hosts
echo "${K8S_NODE1_IP} k8s-node1"  >> /etc/hosts
echo "${K8S_NODE2_IP} k8s-node2"  >> /etc/hosts
echo "${K8S_NODE3_IP} k8s-node3"  >> /etc/hosts

# VARIABLE
cat ./templates/hosts | envsubst > ./hosts
cat ./templates/terraform.tfvars | envsubst > ./terraform/terraform.tfvars
cat ./templates/build.tf | envsubst > ./terraform/build.tf

# Deploy OVF and convert it to template
govc import.ovf "files/ubuntu_ovf/ubuntu.ovf"
govc vm.markastemplate "ubuntu"

# NSX-T configureation
echo "Coniguring NSX-T"
python3 ./nsxtinit_python/nsxt_setup.py -k -m ${NSX_MANAGER_IP} -u admin -p 'VMware1!VMware1!'

# Terraform is used to deploy k8s nodes
echo "Deploying k8s nodes"
cd ./terraform
terraform init
terraform apply -auto-approve
cd ../

exit 0


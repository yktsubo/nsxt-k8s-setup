#!/bin/bash

DOCKER_ENVFILE=$(mktemp)
VCENTER_IP='192.168.110.11'
VCENTER_USER='administrator@vsphere.local'
VCENTER_PASS='VMware1!' 

NSX_USER='admin'
NSX_PASS='VMware1!'
DATASTORE='CompData'
DATACENTER='Datacenter Site A'
CLUSTER='Compute Cluster'


ESXI_01_IP='192.168.120.151'
ESXI_02_IP='192.168.120.152'
ESXI_USER='root'
ESXI_PASS='VMware1!'

NSX_EDGE_01_IP='192.168.110.41'
NSX_EDGE_02_IP='192.168.110.42'
NSX_MANAGER_IP='192.168.110.201'
NSX_CONTROLLER_01_IP='192.168.110.51'
NSX_LB_SIZE='SMALL'

K8S_MGMT_GATEWAY='192.168.120.1'
K8S_MGMT_PREFIX='24'
K8S_MGMT_NETWORK='VM Network'
K8S_MASTER_IP='192.168.120.70'
K8S_NODE1_IP='192.168.120.71'
K8S_NODE2_IP='192.168.120.72'
K8S_NODE3_IP='192.168.120.73'

# VARIABLE
echo "# Variable for nsxt k8s setup docker" > ${DOCKER_ENVFILE}
echo DNS='192.168.110.10' >> ${DOCKER_ENVFILE}
echo DOMAIN='corp.local' >> ${DOCKER_ENVFILE}
echo NTP='192.168.110.10' >> ${DOCKER_ENVFILE}
echo VCENTER_IP=${VCENTER_IP} >> ${DOCKER_ENVFILE}
echo VCENTER_USER='administrator@vsphere.local' >> ${DOCKER_ENVFILE}
echo VCENTER_PASS='VMware1!' >> ${DOCKER_ENVFILE}
echo DATASTORE='CompData' >> ${DOCKER_ENVFILE}
echo DATACENTER='Datacenter Site A' >> ${DOCKER_ENVFILE}
echo CLUSTER='Compute Cluster' >> ${DOCKER_ENVFILE}
echo OVFFILE="~/images/ubuntu_ovf/ubuntu.ovf" >> ${DOCKER_ENVFILE}
echo NSX_MANAGER_IP=${NSX_MANAGER_IP} >> ${DOCKER_ENVFILE}
echo NSX_MANAGER_USER=${NSX_USER} >> ${DOCKER_ENVFILE}
echo NSX_MANAGER_PASS=${NSX_PASS} >> ${DOCKER_ENVFILE}
echo NSX_CONTROLLER_01_IP=${NSX_CONTROLLER_01_IP} >> ${DOCKER_ENVFILE}
echo NSX_CONTROLLER_01_USER=${NSX_USER} >> ${DOCKER_ENVFILE}
echo NSX_CONTROLLER_01_PASS=${NSX_PASS} >> ${DOCKER_ENVFILE}
echo NSX_EDGE_01_IP=${NSX_EDGE_01_IP} >> ${DOCKER_ENVFILE}
echo NSX_EDGE_01_USER=${NSX_USER} >> ${DOCKER_ENVFILE}
echo NSX_EDGE_01_PASS=${NSX_PASS} >> ${DOCKER_ENVFILE}
echo NSX_EDGE_02_IP=${NSX_EDGE_02_IP} >> ${DOCKER_ENVFILE}
echo NSX_EDGE_02_USER=${NSX_USER} >> ${DOCKER_ENVFILE}
echo NSX_EDGE_02_PASS=${NSX_PASS} >> ${DOCKER_ENVFILE}
echo ESXI_01_IP=${ESXI_01_IP} >> ${DOCKER_ENVFILE}
echo ESXI_01_USER=${ESXI_USER} >> ${DOCKER_ENVFILE}
echo ESXI_01_PASS=${ESXI_PASS} >> ${DOCKER_ENVFILE}
echo ESXI_02_IP=${ESXI_02_IP} >> ${DOCKER_ENVFILE}
echo ESXI_02_USER=${ESXI_USER} >> ${DOCKER_ENVFILE}
echo ESXI_02_PASS=${ESXI_PASS} >> ${DOCKER_ENVFILE}
echo GOVC_INSECURE=1 >> ${DOCKER_ENVFILE}
echo GOVC_URL="${VCENTER_IP}" >> ${DOCKER_ENVFILE}
echo GOVC_USERNAME="${VCENTER_USER}" >> ${DOCKER_ENVFILE}
echo GOVC_PASSWORD="${VCENTER_PASS}" >> ${DOCKER_ENVFILE}
echo GOVC_DATASTORE="${DATASTORE}" >> ${DOCKER_ENVFILE}
echo GOVC_NETWORK="VM Network" >> ${DOCKER_ENVFILE}
echo GOVC_RESOURCE_POOL="/${DATACENTER}/host/${CLUSTER}" >> ${DOCKER_ENVFILE}
echo K8S_MASTER_IP=${K8S_MASTER_IP} >> ${DOCKER_ENVFILE}
echo K8S_NODE1_IP=${K8S_NODE1_IP} >> ${DOCKER_ENVFILE}
echo K8S_NODE2_IP=${K8S_NODE2_IP} >> ${DOCKER_ENVFILE}
echo K8S_NODE3_IP=${K8S_NODE3_IP} >> ${DOCKER_ENVFILE}
echo NSX_LB_SIZE=${NSX_LB_SIZE} >> ${DOCKER_ENVFILE}
echo K8S_MGMT_GATEWAY=${K8S_MGMT_GATEWAY} >> ${DOCKER_ENVFILE}
echo K8S_MGMT_PREFIX=${K8S_MGMT_PREFIX} >> ${DOCKER_ENVFILE}
echo K8S_MGMT_NETWORK=${K8S_MGMT_NETWORK} >> ${DOCKER_ENVFILE}

sudo docker run --env-file ${DOCKER_ENVFILE} -it harbor-tenant-01.sg.lab/library/nsxt-k8s-setup:2.2.0

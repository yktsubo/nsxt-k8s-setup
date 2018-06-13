#!/bin/bash

if [[ ! -v OS_USERNAME ]]; then
    echo "You need to set Openstack variable"
    exit 1
fi

DOCKER_ENVFILE="~/.env"

VCENTER_IP=$(neutron floatingip-list -F fixed_ip_address -F floating_ip_address -f csv | grep '192.168.110.11' | cut -d '"' -f 4)
NSX_EDGE_01_IP=$(neutron floatingip-list -F fixed_ip_address -F floating_ip_address -f csv | grep '192.168.110.41' | cut -d '"' -f 4)
NSX_EDGE_02_IP=$(neutron floatingip-list -F fixed_ip_address -F floating_ip_address -f csv | grep '192.168.110.42' | cut -d '"' -f 4)
ESXI_01_IP=$(neutron floatingip-list -F fixed_ip_address -F floating_ip_address -f csv | grep '192.168.120.151' | cut -d '"' -f 4)
ESXI_02_IP=$(neutron floatingip-list -F fixed_ip_address -F floating_ip_address -f csv | grep '192.168.120.152' | cut -d '"' -f 4)
NSX_MANAGER_IP=$(neutron floatingip-list -F fixed_ip_address -F floating_ip_address -f csv | grep '192.168.110.201' | cut -d '"' -f 4)
NSX_CONTROLLER_01_IP=$(neutron floatingip-list -F fixed_ip_address -F floating_ip_address -f csv | grep '192.168.110.51' | cut -d '"' -f 4)

VCENTER_USER='administrator@vsphere.local'
VCENTER_PASS='VMware1!' 

NSX_USER='admin'
NSX_PASS='VMware1!'
DATASTORE='CompData'
DATACENTER='Datacenter Site A'
CLUSTER='Compute Cluster'
ESXI_USER='root'
ESXI_PASS='VMware1!'

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

sudo docker run --env-file ${DOCKER_ENVFILE} -it yuki/nsxt-k8s-setup:0.1 /bin/bash

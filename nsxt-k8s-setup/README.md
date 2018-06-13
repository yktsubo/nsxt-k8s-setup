

# Supported
- Ubuntu16.04
- NSX-T 2.1

# How to use

1. Put files under ./files/ like below

```
files/
├── libopenvswitch_2.8.1.7345072-1_amd64.deb
├── ncp-rc-ubuntu.yml
├── nsx-cni_2.1.3.8356796_amd64.deb
├── nsx-ncp-ubuntu-2.1.3.8356796.tar
├── nsx-node-agent-ds-ubuntu.yml
├── openvswitch-common_2.8.1.7345072-1_amd64.deb
├── openvswitch-datapath-dkms_2.8.1.7345072-1_all.deb
└── openvswitch-switch_2.8.1.7345072-1_amd64.deb
```

2. Edit files
    - answerfile.yml
    - hosts

3. Deploy NSX-T manager/controller/edges

```
ansible-playbook playbooks/deploy_nsxt_components.yml
```

4. Configure NSX-T components
   - Create an overlay transport zone.
   - Add hostnode and transport node   
   - Create an overlay logical switch and connect the Kubernetes nodes to the switch.
   - Create a tier-0 logical router.
   - Create IP blocks for Kubernetes pods.
   - Create IP blocks or IP pools for SNAT (source network address translation).

You can use pynsxt to do above

```
python ./pynsxt/pynsxt/main.py -c ./pynsxt/prepare_infra.yml
python ./pynsxt/pynsxt/main.py -c ./pynsxt/prepare_k8s.yml
```

5. Deploy Ubuntu/Redhat VM which becomes K8s Master/Nodes and attach VMs to k8s transport LS

6. Tag VIF of k8s Nodes

```
python ./pynsxt/pynsxt/main.py -c ./pynsxt/k8s_tag_vif.yml
```

7. Install K8s and NCP

```
ansible-playbook -i ./hosts ./playbooks/deploy_k8s.yml
```
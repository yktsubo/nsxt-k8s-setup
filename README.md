```
nsxt-k8s-setup/
├── defaults.yml
├── deploy_k8s_on_nsxt.sh
├── files
│   ├── libopenvswitch_2.9.1.8502965-1_amd64.deb
│   ├── ncp-rc-ubuntu.yml
│   ├── nsx-cni_2.1.4.8521446_amd64.deb
│   ├── nsx-ncp-ubuntu-2.1.4.8521446.tar
│   ├── nsx-node-agent-ds-ubuntu.yml
│   ├── openvswitch-common_2.9.1.8502965-1_amd64.deb
│   ├── openvswitch-datapath-dkms_2.9.1.8502965-1_all.deb
│   ├── openvswitch-switch_2.9.1.8502965-1_amd64.deb
│   └── ubuntu_ovf
│       ├── ubuntu-1.vmdk
│       ├── ubuntu-2.vmdk
│       └── ubuntu.ovf
├── playbooks
│   ├── deploy_k8s.yml
│   ├── deploy-ncp-plugin.yml
│   ├── kubeadm-init.yml
│   ├── kubeadm-join.yml
│   ├── library
│   │   └── nsxt_deploy.py
│   ├── prep_ansible.yml
│   ├── prep_ncp.yml
│   └── prep_os.yml
├── pynsxt
├── README.md
├── templates
│   ├── answerfile.yml
│   ├── build.tf
│   ├── connect_to_manager.yml
│   ├── hosts
│   ├── k8s_tag_vif.yml
│   ├── prepare_infra.yml
│   ├── prepare_k8s.yml
│   └── terraform.tfvars
└── terraform
    └── variables.tf
```

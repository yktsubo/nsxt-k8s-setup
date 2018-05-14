#!/usr/bin/python
__author__ = 'smetta'
# Import the module
import subprocess
DOCUMENTATION = '''
---
module: vraova_deploy
Short_description: Module for deploying VRA ova through python
description:
    - Provides an interface for deployment of ova in venter
versoin_added: "0.1"
options:
    power_on:
        description:
            -Indicates whether the appliance needs to be powered ons.
        required: True
        default: Null
    vcenter_props:
        description:
            - Dictionary containing vcenter properties.
        required: True
        default: Null
    location_props:
        description:
            - Dictionary containing the location properties of appliance
        required: True
        default: Null
    ova_props:
        description:
            - Dictionary containing the directory and name of the ova file
        required: True
        default: Null
   resource_props
        description:
            - Dictionary containing the properties of the appliance itself
        required: True
        default: Null
    additional_props::
        description:
            - Dictionary containing additional properties of ova such as diskmode, IP  protocol
        required: True
    option_props:
        description:
            - List of options that can be specified for  ovf tool
        required: True
        default: null
'''
EXAMPLES = '''
- name: Deploy  ova through Python
  ignore_errors: yes
  local_action:
    module: ova_deploy
    power_on: "{{vra_poweron}}"
    vcenter_props:
      vcenter_host: "{{ vcenter_host}}"
      vcenter_port: "{{ vcenter_port }}"
      vcenter_user: "{{ vcenter_user|urlencode }}"
      vcenter_password: "{{ vcenter_password|urlencode }}"
    location_props:
      resource_name: "{{ name }}"
      datacenter: "{{ datacenter }}"
      network: "{{ network }}"
      cluster: "{{ cluster }}"
      data_store: "{{ vra_datastore }}"
    ova_props:
      ova_directory: "{{ ova_location }}"
      ova_name: "{{ ova }}"
    additional_props:
     diskMode: 'thin'
     ipProtocol: 'IPv4'
    resource_props:
      varoot-password: "{{vra_root_password}}"
      va-ssh-enabled: "{{vra_ssh_enabled}}"
      vami.hostname: "{{vra_host_name}}"
    option_props:
      - acceptAllEulas
      - allowExtraConfig
      - noSSLVerify

'''


def deploy_ova(module):
    component = module.params.get("component")
    name = module.params.get("name")
    datastore = module.params.get("datastore")
    network = module.params.get("network")
    ip = module.params.get("ip")
    netmask = module.params.get("netmask")
    gateway = module.params.get("gateway")
    dns = module.params.get("dns")
    domain = module.params.get("domain")
    ntp = module.params.get("ntp")
    password = module.params.get("password")
    ova = module.params.get("ova")
    vcenter_username = module.params.get("vcenter_username")
    vcenter_password = module.params.get("vcenter_password")
    vcenter_ip = module.params.get("vcenter_ip")
    datacenter = module.params.get("datacenter")
    cluster = module.params.get("cluster")
    overlay_network = module.params.get("overlay_network")
    vlan_network = module.params.get("vlan_network")
    size = module.params.get("size")

    # Create deploy command
    cmd = ["ovftool"]
    # Default variable
    cmd.append("--X:injectOvfEnv")
    cmd.append("--allowExtraConfig")
    cmd.append("--acceptAllEulas")
    cmd.append("--noSSLVerify")
    cmd.append("--diskMode=thin")
    cmd.append("--powerOn")
    cmd.append("--name=%s" % name)
    cmd.append("--datastore=%s" % datastore)
    cmd.append("--prop:nsx_ip_0=%s" % ip)
    cmd.append("--prop:nsx_netmask_0=%s" % netmask)
    cmd.append("--prop:nsx_gateway_0=%s" % gateway)
    cmd.append("--prop:nsx_dns1_0=%s" % dns)
    cmd.append("--prop:nsx_domain_0=%s" % domain)
    cmd.append("--prop:nsx_ntp_0=%s" % ntp)
    cmd.append("--prop:nsx_isSSHEnabled=True")
    cmd.append("--prop:nsx_allowSSHRootLogin=True")
    cmd.append("--prop:nsx_passwd_0=%s" % password)
    cmd.append("--prop:nsx_cli_passwd_0=%s" % password)
    cmd.append("--prop:nsx_hostname=%s" % name)

    if component == 'manager':
        cmd.append("--network=%s" % network)
        cmd.append("--prop:nsx_role=nsx-manager")
        cmd.append("--deploymentOption=%s" % size)

    elif component == 'controller':
        cmd.append("--network=%s" % network)
    elif component == 'edge':
        cmd.append("--deploymentOption=%s" % size)
        cmd.append("--net:Network 0=%s" % network)
        cmd.append("--net:Network 1=%s" % overlay_network)
        cmd.append("--net:Network 2=%s" % vlan_network)
        cmd.append("--net:Network 3=%s" % vlan_network)

    cmd.append(ova)
    try:
        cmd.append("vi://%s:%s@%s/%s/host/%s" % (vcenter_username,
                                                 vcenter_password,
                                                 vcenter_ip,
                                                 datacenter,
                                                 cluster))
        output, error = subprocess.Popen(cmd, universal_newlines=True,
                                         stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
        return False, output
    except Exception as a:
        return True, dict(msg=str(a))


def main():
    module = AnsibleModule(
        argument_spec=dict(
            component=dict(required=True, type='str'),
            name=dict(required=True, type='str'),
            datastore=dict(required=True, type='str'),
            network=dict(required=True, type='str'),
            ip=dict(required=True, type='str'),
            netmask=dict(required=True, type='str'),
            gateway=dict(required=True, type='str'),
            dns=dict(required=True, type='str'),
            domain=dict(required=True, type='str'),
            ntp=dict(required=True, type='str'),
            password=dict(required=True, type='str'),
            ova=dict(required=True, type='str'),
            vcenter_username=dict(required=True, type='str'),
            vcenter_password=dict(required=True, type='str'),
            vcenter_ip=dict(required=True, type='str'),
            datacenter=dict(required=True, type='str'),
            cluster=dict(required=True, type='str'),
            overlay_network=dict(required=False, type='str'),
            vlan_network=dict(required=False, type='str'),
            size=dict(required=False, type='str')
        )
    )

    try:
        fail, result = deploy_ova(module)
    except Exception as e:
        import traceback
        module.fail_json(msg='%s: %s\n%s' %
                         (e.__class__.__name__, str(e), traceback.format_exc()))
    if fail:
        module.fail_json(msg=result)
    else:
        module.exit_json(changed=True, msg=result)


from ansible.module_utils.basic import *

if __name__ == '__main__':
    main()

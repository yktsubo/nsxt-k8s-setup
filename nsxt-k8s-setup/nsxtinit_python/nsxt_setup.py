#!/usr/bin/env python

import requests
import argparse
import json
import re
import ssl
import socket
import hashlib
import sys
import time
import paramiko
from pprint import pprint
from requests.packages.urllib3.exceptions import InsecureRequestWarning


# VARIABLE

# Define your custome args
def _custom_args(parser):
    pass

# Implement your logic here
def _nsx_api(session, args, method, path, data):
    nsx_url = 'https://%s:%s' % (args.nsxmip, 443)
    url = nsx_url + path
    try:    
        if method == 'post':
            response = session.post(url, json=data)
            response = response.json()            
        elif method == 'get':
            response = session.get(url)
            response = response.json()                        
        elif method == 'put':
            response = session.put(url, json=data)
            response = response.json()
    except:
        print('ERROR: ' + method + ' to ' + path)
        response = {}

    if 'error_code' in response:
        print('ERROR: ' + method + ' to ' + path)        
        pprint(response)
    
    return response


def _create_overlay_tz(session, args):
    data = {
        "transport_type" : "OVERLAY",
        "host_switch_name" : "NVDS-0",
        "host_switch_mode" : "STANDARD",
        "nested_nsx" : True,
        "resource_type" : "TransportZone",
        "display_name" : "OVERLAY",
        "description" : "Overlay Transport Zone (Provisioned by API using nested_nsx parameter)"
    }
    response = _nsx_api(session, args, 'post', '/api/v1/transport-zones/', data)
    return response

def _create_combined_vlan_tz(session, args):
    data = {
        "transport_type" : "VLAN",
        "host_switch_name" : "NVDS-0",
        "host_switch_mode" : "STANDARD",
        "resource_type" : "TransportZone",
        "display_name" : "VLAN",
        "description" : "VLAN Transport Zone for ESXi"
    }
    response = _nsx_api(session, args, 'post', '/api/v1/transport-zones/', data)
    return response    

def _create_uplink1_vlan_tz(session, args):
    data = {
        "transport_type" : "VLAN",        
        "host_switch_name" : "NVDS-VLAN1",        
        "host_switch_mode" : "STANDARD",
        "resource_type" : "TransportZone",
        "display_name" : "UPLINK_VLAN1",
        "description" : "VLAN Transport Zone for Uplink1"        
    }
    response = _nsx_api(session, args, 'post', '/api/v1/transport-zones/', data)
    return response


def _create_esxi_uplink_profile(session, args):
    data = {
        "teaming" : {
            "policy" : "FAILOVER_ORDER",            
            "active_list" : [ {
                "uplink_name" : "uplink1",
                "uplink_type" : "PNIC"
            }]
        },
        "transport_vlan" : 107,
        "resource_type" : "UplinkHostSwitchProfile",
        "display_name" : "esxi-uplink-profile"
    }
    response = _nsx_api(session, args, 'post', '/api/v1/host-switch-profiles', data)
    return response


def _create_edge_uplink_profile(session, args):
    data = {
        "teaming" : {
            "policy" : "FAILOVER_ORDER",            
            "active_list" : [ {
                "uplink_name" : "uplink1",
                "uplink_type" : "PNIC"
            }]
        },
        "transport_vlan" : 0,
        "resource_type" : "UplinkHostSwitchProfile",
        "display_name" : "edge-uplink-profile"
    }
    response = _nsx_api(session, args, 'post', '/api/v1/host-switch-profiles', data)
    return response

def _create_esxi_tep_ip_pool(session, args):
    data = {
        "display_name": "TEP-ESXI",
        "description": "TEP IP pool for ESXI",
        "subnets": [
            {
                "allocation_ranges": [
                    {
                        "start": "192.168.107.151",
                        "end": "192.168.107.160"
                    }
                ],
                "gateway_ip": "192.168.107.1",
                "cidr": "192.168.107.0/24"
            }
        ]
    }
    response = _nsx_api(session, args, 'post', '/api/v1/pools/ip-pools', data)
    return response


def _create_edge_tep_ip_pool(session, args):
    data = {
        "display_name": "TEP-EDGE",
        "description": "TEP IP pool for EDGE",
        "subnets": [
            {
                "allocation_ranges": [
                    {
                        "start": "192.168.108.151",
                        "end": "192.168.108.160"
                    }
                ],
                "gateway_ip": "192.168.108.1",
                "cidr": "192.168.108.0/24"
            }
        ]
    }
    response = _nsx_api(session, args, 'post', '/api/v1/pools/ip-pools', data)
    return response



def _get_thumbprint(ip):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    wrappedSocket = ssl.wrap_socket(sock)

    try:
        wrappedSocket.connect((ip, 443))
    except:
        response = False
    else:
        der_cert_bin = wrappedSocket.getpeercert(True)
        pem_cert = ssl.DER_cert_to_PEM_cert(wrappedSocket.getpeercert(True))
        # Thumbprint
        thumb_sha256 = hashlib.sha256(der_cert_bin).hexdigest()
        wrappedSocket.close()
        return ':'.join(map(''.join, zip(*[iter(thumb_sha256)] * 2)))

def _create_esxi_tn(session, args):

    hosts = [
        {
            'ip': "192.168.109.151",
            'hostname': "esxcomp-01a"
        },
        {
            'ip': "192.168.109.152",
            'hostname': "esxcomp-02a"
        },
        {
            'ip': "192.168.109.153",
            'hostname': "esxcomp-03a"
        }
    ]


    for host in hosts:
        thumbprint = _get_thumbprint(host['ip'])
        data = {
            "resource_type": "HostNode",
            "display_name": host['hostname'],
            "ip_addresses": [ host['ip'] ],
            "os_type": "ESXI",
            "os_version": "6.7.0",
            "host_credential": {
                "username": "root",
                "password": "VMware1!",
                "thumbprint":  thumbprint
            }
        }
        fabric_node = _nsx_api(session, args, 'post', '/api/v1/fabric/nodes/', data)
        node_uuid = fabric_node['id']
        
        node_initializing = True
        retry_num = 0
        while node_initializing:
            try:
                fabric_node_status = _nsx_api(session, args, 'get', '/api/v1/fabric/nodes/' + node_uuid + '/status',"")
                if fabric_node_status['host_node_deployment_status'] == 'INSTALL_SUCCESSFUL':
                    node_initializing = False
            except:
                print('Retrying')
            time.sleep(30)
            retry_num += 1
            if retry_num > 10:
                print('ERROR to install computes')
                sys.exit(1)
     
        data = { 
            "node_id" :node_uuid,
            "resource_type" : "TransportNode",
            "display_name" : host['hostname'],
            "transport_zone_endpoints" : [ {
                "transport_zone_id" : args.overlay_tz_uuid
            }, {
                "transport_zone_id" : args.combined_vlan_tz_uuid
            } ],
            "host_switch_spec" : {
                "host_switches" : [ {
                    "host_switch_name" : "NVDS-0",
                    "host_switch_profile_ids" : [ {
                        "key" : "UplinkHostSwitchProfile",                    
                        "value" : args.esxi_uplinkprofile_uuid
                    }],
                    "pnics" : [ {
                        "device_name" : "vmnic1",
                        "uplink_name" : "uplink1"
                    } ],
                    "is_migrate_pnics" : True,
                    "ip_assignment_spec" : {
                        "ip_pool_id" : args.esxi_tep_ippool_uuid,
                        "resource_type" : "StaticIpPoolSpec"
                    }
                } ],
                "resource_type" : "StandardHostSwitchSpec"
            }
        }

        _nsx_api(session, args, 'post', '/api/v1/transport-nodes',data)

                
    pass

def _connect_cli(config):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(config['ip'], username=config['username'],
                password=config['password'], port=22, timeout=15.0, look_for_keys=False)
    return ssh

def _register_edge(session, args):

    nsxManager = {
        'ip': '192.168.110.201',
        'username': 'admin',
        'password': 'VMware1!VMware1!'
    }
    
    edges = [
        {
            'ip': "192.168.110.41",
            'username': 'admin',
            'password': 'VMware1!VMware1!',            
            'hostname': "nsxedge-01a"
        },
        {
            'ip': "192.168.110.42",
            'username': 'admin',
            'password': 'VMware1!VMware1!',            
            'hostname': "nsxedge-02a"
        }
    ]
    response = _nsx_api(session, args, 'get', '/api/v1/cluster/nodes/', "")
    thumbprint = ''
    for val in response['results']:
        if 'manager_role' in val:
            thumbprint = val['manager_role']['api_listen_addr']['certificate_sha256_thumbprint']
            

    for edge in edges:
        cli = _connect_cli(edge)
        stdin, stdout, stderr = cli.exec_command(
            "join management-plane %s username %s password %s thumbprint %s" % (nsxManager['ip'], nsxManager['username'],  nsxManager['password'], thumbprint))
        for line in stdout:
            if len(line.strip()) == 0:
                continue
            elif 'Node successfully registered' in line:
                break
    pass
def _configure_edge(session, args):

    ret = []
    
    tn_lists = _nsx_api(session, args, 'get', '/api/v1/transport-nodes/', "")

    for edge in tn_lists['results']:
        if edge['node_deployment_info']['resource_type'] != 'EdgeNode':
            continue
        data = { 
            "resource_type" : "TransportNode",
            "id": edge['id'],
            "_revision": edge['_revision'],
            "display_name" : edge['display_name'],
            "node_id" : edge['node_id'],            
            "transport_zone_endpoints" : [ {
                "transport_zone_id" : args.overlay_tz_uuid
            }, {
                "transport_zone_id" : args.uplink1_vlan_tz_uuid
            } ],
            "host_switch_spec" : {
                "host_switches" : [
                    {
                        "host_switch_name" : "NVDS-0",
                        "host_switch_profile_ids" : [ {
                            "key" : "UplinkHostSwitchProfile",                    
                            "value" : args.edge_uplinkprofile_uuid
                        }],
                        "pnics" : [ {
                            "device_name" : "fp-eth0",
                            "uplink_name" : "uplink1"
                        } ],
                        "ip_assignment_spec" : {
                            "ip_pool_id" : args.edge_tep_ippool_uuid,
                            "resource_type" : "StaticIpPoolSpec"
                        }
                    },
                    {
                        "host_switch_name" : "NVDS-VLAN1",
                        "host_switch_profile_ids" : [ {
                            "key" : "UplinkHostSwitchProfile",                    
                            "value" : args.edge_uplinkprofile_uuid
                        }],
                        "pnics" : [ {
                            "device_name" : "fp-eth1",
                            "uplink_name" : "uplink1"
                        } ]
                    }                    
                ],
                "resource_type" : "StandardHostSwitchSpec"
            }
        }
        if edge['display_name'] == 'nsxedge-01a':
            args.edge1_uuid = edge['id']
        elif edge['display_name'] == 'nsxedge-02a':
            args.edge2_uuid = edge['id']
        tn = _nsx_api(session, args, 'post', '/api/v1/transport-nodes/' ,data)
    return 

def _create_edge_cluster(session, args):
    data = {
        "display_name": "EdgeCluster",
        "members":  [
        ]
    }
    data['members'].append({"transport_node_id" : args.edge1_uuid})
    data['members'].append({"transport_node_id" : args.edge2_uuid})

    node_initializing = True
    retry_num = 0
    while node_initializing:
        try:
            edge_cluster = _nsx_api(session, args, 'post', '/api/v1/edge-clusters', data)
            _nsx_api(session, args, 'get', '/api/v1/edge-clusters/' + edge_cluster['id'], '')
            node_initializing = False
        except:
            print('Retrying')
        time.sleep(30)
        retry_num += 1
        if retry_num > 10:
            print('ERROR to install computes')
            sys.exit(1)
    return edge_cluster

def _create_uplink1_ls(session, args):
    data =  {
        "transport_zone_id" : args.uplink1_vlan_tz_uuid,
        "vlan" : 0,
        "admin_state" : "UP",
        "resource_type" : "LogicalSwitch",
        "display_name" : "ls-uplink1",
        "description" : "Uplink1 LS"
    }
    response = _nsx_api(session, args, 'post', '/api/v1/logical-switches', data)
    return response


def _create_t0(session, args):
    data = {
        "resource_type": "LogicalRouter",
        "description": "Tier0 Router for k8s",
        "display_name": "tier-0",
        "edge_cluster_id": args.edge_cluster_uuid,
        "router_type": "TIER0",
        "high_availability_mode": "ACTIVE_STANDBY"
    }
    response = _nsx_api(session, args, 'post', '/api/v1/logical-routers', data)
    args.t0_uuid = response['id']

    uplink1_edge1_data = {
        'logical_switch_id': args.uplink1_vlan_ls_uuid,
        'display_name': "Uplink1onEdge1",
        'admin_state': 'UP'
    }
    uplink1_edge1_res = _nsx_api(session, args, 'post', '/api/v1/logical-ports', uplink1_edge1_data)
    
    uplink1_edge2_data = {
        'logical_switch_id': args.uplink1_vlan_ls_uuid,
        'display_name': "Uplink1onEdge2",
        'admin_state': 'UP'
    }
    uplink1_edge2_res = _nsx_api(session, args, 'post', '/api/v1/logical-ports', uplink1_edge2_data)

    edge_cluster = _nsx_api(session, args, 'get', '/api/v1/edge-clusters/' + args.edge_cluster_uuid, '')
    for edge_member in edge_cluster['members']:
        if edge_member['transport_node_id'] == args.edge1_uuid:
            args.edge1_member_id = edge_member['member_index']
        elif edge_member['transport_node_id'] == args.edge2_uuid:
            args.edge2_member_id = edge_member['member_index']
    
    uplink1_rp_data = {
        'display_name': 'Uplink1onEdge1',
        'resource_type': 'LogicalRouterUpLinkPort',
        'logical_router_id': args.t0_uuid,
        'linked_logical_switch_port_id': {
            'target_id': uplink1_edge1_res['id']
        },
        'edge_cluster_member_index': [args.edge1_member_id],
        'subnets': [{
            'ip_addresses': ['192.168.105.1'],
            'prefix_length': '24'
        }]
    }
    _nsx_api(session, args, 'post', '/api/v1/logical-router-ports', uplink1_rp_data)
    uplink2_rp_data = {
        'display_name': 'Uplink1onEdge1',
        'resource_type': 'LogicalRouterUpLinkPort',
        'logical_router_id': args.t0_uuid,
        'linked_logical_switch_port_id': {
            'target_id': uplink1_edge2_res['id']
        },
        'edge_cluster_member_index': [args.edge2_member_id],
        'subnets': [{
            'ip_addresses': ['192.168.105.2'],
            'prefix_length': '24'
        }]
    }
    _nsx_api(session, args, 'post', '/api/v1/logical-router-ports', uplink2_rp_data)
            
            
    redist_data = _nsx_api(session, args, 'get', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/redistribution', "")
    redist_data["bgp_enabled"] = True
    _nsx_api(session, args, 'put', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/redistribution', redist_data)
    redist_rule_data = _nsx_api(session, args, 'get', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/redistribution/rules', "")
    redist_rule = {
        "sources" : [ "T0_NAT", "T1_CONNECTED", "T1_NAT", "T1_LB_VIP" ],
        "destination" : "BGP",
        "address_family" : "IPV4_AND_IPV6",
        "display_name" : "RedistributionRule"
    }
    redist_rule_data['rules'].append(redist_rule)
    _nsx_api(session, args, 'put', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/redistribution/rules', redist_rule_data)


    bgp_data = _nsx_api(session, args, 'get', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/bgp', "")
    bgp_data["enabled"] = True
    bgp_data["ecmp"] = True    
    bgp_data["as_number"] = '100'
    bgp_data["as_num"] = '100'
    _nsx_api(session, args, 'put', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/bgp', bgp_data)

    bgp_nei1_data = {
        "display_name": "vx01",
        "neighbor_address": "192.168.105.11",
        "remote_as_num": "250",
        "enable_bfd" : True
    }
    _nsx_api(session, args, 'post', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/bgp/neighbors', bgp_nei1_data)

    bgp_nei2_data = {
        "display_name": "vx02",
        "neighbor_address": "192.168.105.12",
        "remote_as_num": "250",
        "enable_bfd" : True        
    }
    _nsx_api(session, args, 'post', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/bgp/neighbors', bgp_nei2_data)

    bfd_data = _nsx_api(session, args, 'get', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/bfd-config', "")
    bfd_data["enabled"] = True
    _nsx_api(session, args, 'put', '/api/v1/logical-routers/' + args.t0_uuid + '/routing/bfd-config', bfd_data)

    pass

def _run(session, args):

    # Configure TZ
    r = _create_overlay_tz(session, args)
    args.overlay_tz_uuid = r['id']
    r = _create_combined_vlan_tz(session, args)
    args.combined_vlan_tz_uuid = r['id']    
    r = _create_uplink1_vlan_tz(session, args)
    args.uplink1_vlan_tz_uuid = r['id']
    
    # Configure UplinkProfile
    r = _create_esxi_uplink_profile(session, args)
    args.esxi_uplinkprofile_uuid = r['id']
    r = _create_edge_uplink_profile(session, args)
    args.edge_uplinkprofile_uuid = r['id']    
    # Configure IP Pool for TEP
    r = _create_esxi_tep_ip_pool(session, args)
    args.esxi_tep_ippool_uuid = r['id']            
    r = _create_edge_tep_ip_pool(session, args)    
    args.edge_tep_ippool_uuid = r['id']            

    # Configure TransportNode
    _create_esxi_tn(session, args)
    
    # Configure Edge
    _register_edge(session, args)
    _configure_edge(session, args)

    # Configure EdgeCluster
    r = _create_edge_cluster(session, args)
    args.edge_cluster_uuid = r['id']

    # [Optional] Configure ComputeManager
    # [Optional] Configure VIP
    # Configure LS
    r = _create_uplink1_ls(session, args)
    args.uplink1_vlan_ls_uuid = r['id']
    
    # Configure T0
    _create_t0(session, args)
    pass


# DO NOT CHANGE AFTER HERE

def get_args():
    parser = argparse.ArgumentParser(description='NSX-T python script')

    parser.add_argument('-d',
                        '--debug',
                        default=False,
                        action='store_true',
                        help='print low level debug of http transactions')

    parser.add_argument('-k',
                        '--insecure',
                        default=False,
                        action='store_true',
                        help='To disable validation of Manager certification')

    parser.add_argument('-m',
                        '--nsxmip',
                        required=True,
                        help='nsxt manager ip')

    parser.add_argument('-u',
                        '--username',
                        default='admin',
                        required=False,
                        help='nsxt username')

    parser.add_argument('-p',
                        '--password',
                        default='VMware1!VMware1!',
                        required=False,
                        help='nsxt password')

    _custom_args(parser)
    parser.set_defaults(func=_run)
    return parser.parse_args()


def _get_api_client(username, password, insecure=False):
    requests.packages.urllib3.disable_warnings(
        InsecureRequestWarning)  # Disable SSL warnings
    session = requests.session()
    session.verify = not insecure
    session.auth = (username, password)
    session.headers.update({'content-type': 'application/json'})
    return session


def main():
    args = get_args()
    session = _get_api_client(args.username,
                              args.password, insecure=args.insecure)
    args.func(session, args)


if __name__ == '__main__':
    main()





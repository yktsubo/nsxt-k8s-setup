
# Configure the VMware vSphere Provider
provider "vsphere" {
  vsphere_server = "${var.vsphere_vcenter}"
  user = "${var.vsphere_user}"
  password = "${var.vsphere_password}"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "${var.vsphere_cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network1" {
  name          = "VM Network"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network2" {
  name          = "k8s-transport"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "ubuntu"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}


resource "vsphere_virtual_machine" "k8s-master" {
  name = "k8s-master"
  num_cpus = 2
  memory   = 4096
  wait_for_guest_net_timeout = 0
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network1.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface {
    network_id   = "${data.vsphere_network.network2.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[1]}"
  }
  
  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }
  disk {
    label            = "disk1"
    size             = "${data.vsphere_virtual_machine.template.disks.1.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.1.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.1.thin_provisioned}"
    unit_number = 1
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "k8s-master"
        domain    = "${DOMAIN}"
        time_zone = "UTC"
      }

      network_interface {
        ipv4_address = "192.168.120.70"
        ipv4_netmask = 24
      }
      dns_server_list = ["${DNS}"]
      dns_suffix_list =  ["${DOMAIN}"]
      ipv4_gateway = "192.168.120.1"
      network_interface {
      }
      
    }
  }
}

resource "vsphere_virtual_machine" "k8s-node1" {
  name = "k8s-node1"
  num_cpus = 2
  memory   = 4096
  wait_for_guest_net_timeout = 0
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network1.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface {
    network_id   = "${data.vsphere_network.network2.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[1]}"
  }
  
  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  disk {
    label            = "disk1"
    size             = "${data.vsphere_virtual_machine.template.disks.1.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.1.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.1.thin_provisioned}"
    unit_number = 1
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "k8s-node1"
        domain    = "${DOMAIN}"
        time_zone = "UTC"
      }

      network_interface {
        ipv4_address = "192.168.120.71"
        ipv4_netmask = 24
      }
      dns_server_list = ["${DNS}"]
      dns_suffix_list =  ["${DOMAIN}"]
      ipv4_gateway = "192.168.120.1"
      network_interface {
      }
      
    }
  }
}

resource "vsphere_virtual_machine" "k8s-node2" {
  name = "k8s-node2"
  num_cpus = 2
  memory   = 4096
  wait_for_guest_net_timeout = 0
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network1.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface {
    network_id   = "${data.vsphere_network.network2.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[1]}"
  }
  
  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  disk {
    label            = "disk1"
    size             = "${data.vsphere_virtual_machine.template.disks.1.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.1.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.1.thin_provisioned}"
    unit_number = 1
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "k8s-node2"
        domain    = "${DOMAIN}"
        time_zone = "UTC"
      }

      network_interface {
        ipv4_address = "192.168.120.72"        
        ipv4_netmask = 24
      }
      dns_server_list = ["${DNS}"]
      dns_suffix_list =  ["${DOMAIN}"]
      ipv4_gateway = "192.168.120.1"
      network_interface {
      }
      
    }
  }
}


resource "vsphere_virtual_machine" "k8s-node3" {
  name = "k8s-node3"
  num_cpus = 2
  memory   = 4096
  wait_for_guest_net_timeout = 0
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network1.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  network_interface {
    network_id   = "${data.vsphere_network.network2.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[1]}"
  }
  
  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  disk {
    label            = "disk1"
    size             = "${data.vsphere_virtual_machine.template.disks.1.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.1.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.1.thin_provisioned}"
    unit_number = 1
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "k8s-node3"
        domain    = "${DOMAIN}"
        time_zone = "UTC"
      }

      network_interface {
        ipv4_address = "192.168.120.73"
        ipv4_netmask = 24
      }
      dns_server_list = ["${DNS}"]
      dns_suffix_list =  ["${DOMAIN}"]
      ipv4_gateway = "192.168.120.1"
      network_interface {
      }
      
    }
  }
}

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Imagen base
resource "libvirt_volume" "debian_base" {
  name   = "debian12-base.qcow2"
  pool   = "default"
  source = var.debian_image_url
  format = "qcow2"
}


# 2. Cloud-Init 
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  pool      = "default"
  user_data = <<-EOF
    #cloud-config
    users:
      - name: admin
        sudo: ALL=(ALL) NOPASSWD:ALL
        groups: sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${file("~/.ssh/id_rsa.pub")}
    growpart:
      mode: auto
      devices: ['/']
  EOF
}

#3. Discos OS
resource "libvirt_volume" "os_disk" {
  count          = var.node_count
  name           = "nodo${count.index + 1}-os.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.debian_base.id
  size           = var.os_disk_size
}

# 4. Discos GlusterFS
resource "libvirt_volume" "gluster_disk" {
  count = var.node_count
  name  = "nodo${count.index + 1}-gluster-brick.qcow2"
  pool  = "default"
  size  = var.gluster_disk_size
}

# 5. Máquinas Virtuales
resource "libvirt_domain" "gluster_node" {
  count  = var.node_count
  name   = "gluster-nodo${count.index + 1}"
  memory = var.vm_memory
  vcpu   = var.vm_vcpu

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = var.libvirt_network
    wait_for_lease = true
    addresses	   = ["192.168.122.${count.index + 101}"]
  }

  disk {
    volume_id = libvirt_volume.os_disk[count.index].id
  }

  disk {
    volume_id = libvirt_volume.gluster_disk[count.index].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# 6. Outputs
output "node_ips" {
  description = "IPs asignadas a los nodos de GlusterFS"
  value       = libvirt_domain.gluster_node[*].network_interface[0].addresses[0]
}

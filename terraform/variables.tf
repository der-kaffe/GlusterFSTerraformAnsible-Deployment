variable "node_count" {
  description = "Número de nodos para el clúster de GlusterFS"
  type        = number
  default     = 3
}

variable "vm_memory" {
  description = "Memoria RAM en MB para cada nodo"
  type        = string
  default     = "1024"
}

variable "vm_vcpu" {
  description = "Cantidad de vCPUs por nodo"
  type        = number
  default     = 1
}

variable "os_disk_size" {
  description = "Tamaño del disco del Sistema Operativo en bytes (10GB por defecto)"
  type        = number
  default     = 10737418240
}

variable "gluster_disk_size" {
  description = "Tamaño del disco dedicado a GlusterFS en bytes (5GB por defecto)"
  type        = number
  default     = 5368709120
}

variable "admin_password" {
  description = "Contraseña root para acceso SSH"
  type        = string
  sensitive   = true
}

variable "debian_image_url" {
  description = "URL de la imagen base de Debian"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
}

variable "libvirt_network" {
  description = "Nombre de la red de KVM a utilizar"
  type        = string
  default     = "default"
}

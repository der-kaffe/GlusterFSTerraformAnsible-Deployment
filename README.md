# Despliegue de GlusterFS con Terraform y Ansible

Proyecto de demostración para crear un clúster GlusterFS de tres nodos sobre KVM/libvirt y configurarlo automáticamente con Ansible.

## Arquitectura

El despliegue crea:

- 3 máquinas virtuales Debian 12.
- Un disco de sistema y un disco dedicado a cada nodo.
- Direcciones IP estáticas en la red libvirt `default`.
- Un volumen GlusterFS replicado en los tres nodos.
- Un montaje compartido disponible en `/mnt/gluster_compartido`.

| Nodo | Dirección IP | Rol |
|---|---:|---|
| `nodo1` | `192.168.122.101` | Nodo principal |
| `nodo2` | `192.168.122.102` | Nodo GlusterFS |
| `nodo3` | `192.168.122.103` | Nodo GlusterFS |

## Requisitos

- Host Linux con KVM, QEMU y libvirt configurados.
- Terraform.
- Ansible.
- Acceso a la red libvirt `default`.
- Una clave SSH disponible para el usuario `admin`.

Comprueba que libvirt está activo:

```bash
sudo systemctl status libvirtd
virsh net-list --all
```

## Despliegue de la infraestructura

Desde el directorio `terraform`:

```bash
terraform init
terraform plan
terraform apply
```

Terraform descargará la imagen cloud de Debian, creará los discos y levantará las tres máquinas virtuales.

Para consultar las direcciones asignadas:

```bash
terraform output node_ips
```

También puedes verificar las máquinas desde el host:

```bash
virsh list --all
```

## Configuración de GlusterFS

Cuando las máquinas estén disponibles, ejecuta el playbook desde la raíz del proyecto:

```bash
ansible-playbook -i ansible/inventory.ini ansible/gluster-setup.yml
```

El playbook realiza las siguientes tareas:

1. Registra las claves SSH de los nodos.
2. Instala GlusterFS, XFS y las utilidades de particionado.
3. Prepara y monta `/dev/vdb1` en cada nodo.
4. Une los nodos al clúster GlusterFS.
5. Crea el volumen replicado `vol_shared`.
6. Monta el volumen en `/mnt/gluster_compartido` en todos los nodos.

## Verificación

Comprueba el estado del clúster desde el primer nodo:

```bash
ssh admin@192.168.122.101
sudo gluster peer status
sudo gluster volume info
sudo gluster volume status
```

Verifica el montaje compartido:

```bash
mount | grep gluster
df -h | grep gluster
```

Para probar la replicación, crea un archivo en un nodo:

```bash
echo "Hola desde GlusterFS" | sudo tee /mnt/gluster_compartido/prueba.txt
```

Después, revisa el archivo desde cualquiera de los otros nodos:

```bash
cat /mnt/gluster_compartido/prueba.txt
```

## Personalización

Los valores principales se encuentran en `terraform/terraform.tfvars`:

```hcl
node_count        = 3
vm_memory         = "1024"
vm_vcpu           = 1
os_disk_size      = 10737418240
gluster_disk_size = 5368709120
libvirt_network   = "default"
```

El inventario Ansible está en `ansible/inventory.ini`. Si se cambian las direcciones IP, actualiza también el inventario y las referencias del playbook.

## Destrucción del laboratorio

Para eliminar las máquinas virtuales y sus discos:

```bash
cd terraform
terraform destroy
```

> Este proyecto está pensado como laboratorio y demostración de automatización con Terraform, Ansible, KVM/libvirt y GlusterFS.

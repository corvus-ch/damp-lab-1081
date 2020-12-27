# Installation of the cluster

## Setup:

* Four Raspberry Pi 4 with 8GB ram
* Connected to a router providing DHCP
* The IP addresses are fixed based on the Pis mac address (172.16.42.50-172.16.42.53)
* Three Pis have a USB disk connected.

## Get the disk image

    wget https://cdimage.ubuntu.com/releases/20.04.1/release/ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz
    echo "aadc64a1d069c842e56a4289fe1a6b4b5a0af4efcf95bcce78eb2a80fe5270f4 *ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz" | shasum -a 256 --check
    xz -d ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz

## Prepare SD card

    diskutil unmountDisk /dev/disk4
    pv ubuntu-20.04.1-preinstalled-server-arm64+raspi.img | sudo dd of=/dev/disk4 bs=32m
    cat <<EOF > /Volumes/system-boot/user-data
    #cloud-config
    # vim: syntax=yaml

    hostname: k3s-02

    # Enable password authentication with the SSH daemon
    ssh_import_id:
      - gh:corvus-ch

    # Update apt database and upgrade packages on first boot
    package_update: true
    package_upgrade: true
    EOF
    sed -i'' -e 's/$/ cgroup_memory=1 cgroup_enable=memory/' /Volumes/system-boot/cmdline.txt
    diskutil unmountDisk /dev/disk4

## Prepare USB disk

    sgdisk --zap-all /dev/sda
    parted /dev/sda mklabel gpt
    parted -a opt /dev/sda mkpart primary ext4 0% 100%
    mkfs.ext4 -qFL longhorn /dev/sda1
    mkdir -p /var/lib/longhorn
    echo "LABEL=longhorn /var/lib/longhorn ext4 defaults 0 2" >> /etc/fstab
    mount -a

## Install k3s

    export K3SUP_SSH_KEY=~/.ssh/…
    export K3SUP_SERVER_IP=172.16.42.50
    export K3SUP_EXTRA_ARGS='--disable servicelb --disable traefik --disable local-storage'
    k3sup install \
      --cluster \
      --ip "${K3SUP_SERVER_IP}" \
      --k3s-extra-args "${K3SUP_EXTRA_ARGS}" \
      --ssh-key "${K3SUP_SSH_KEY}" \
      --user ubuntu
    for i in {1..2}; do
      k3sup join \
        --ip 172.16.42.5$i \
        --k3s-extra-args "${K3SUP_EXTRA_ARGS}" \
        --server \
        --server-ip ${K3SUP_SERVER_IP} \
        --ssh-key "${K3SUP_SSH_KEY}" \
        --user ubuntu
    done
    k3sup join \
      --ip 172.16.42.53 \
      --server-ip ${K3SUP_SERVER_IP} \
      --ssh-key "${K3SUP_SSH_KEY}" \
      --user ubuntu

## Label nodes

   kubectl label node -l 'node-role.kubernetes.io/master!=true' node-role.kubernetes.io/worker=true
   kubectl label node/k3s-02 node/k3s-03 node/k3s-04 node.longhorn.io/create-default-disk=true

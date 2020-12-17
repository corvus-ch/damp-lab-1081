# Installation of the cluster

## Setup:

* Four Raspberry Pi 4 with 8GB ram
* Connected to a router providing DHCP
* The IP addresses are fixed based on the Pis mac address (172.16.42.50-172.16.42.53)
* Three Pis have a USB disk connected.
* The USB disk are plain without any file system on them (`sgdisk --zap-all …`)

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

## Install k3s

    export K3SUP_SERVER_IP=172.16.42.50
    export K3SUP_SSH_KEY=~/.ssh/…
    k3sup install --ssh-key "${K3SUP_SSH_KEY}" --user ubuntu --cluster --k3s-extra-args '--disable servicelb --disable traefik' --user ubuntu --ip "${K3SUP_SERVER_IP}"
    for i in {1..2}; do k3sup join --ssh-key "${K3SUP_SSH_KEY}" --user ubuntu --server --server-ip ${K3SUP_SERVER_IP} --ip 172.16.42.5$i; done
    k3sup join --ssh-key "${K3SUP_SSH_KEY}" --user ubuntu} --server-ip ${K3SUP_SERVER_IP} --ip 172.16.42.53

## Label nodes

   kubectl label node -l 'node-role.kubernetes.io/master!=true' node-role.kubernetes.io/worker=true

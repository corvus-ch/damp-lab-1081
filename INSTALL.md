# Installation of the cluster

Based on:

* https://blog.hypriot.com/getting-started-with-docker-and-mac-on-the-raspberry-pi/
* https://blog.hypriot.com/post/setup-kubernetes-raspberry-pi-cluster/ 

## Prepare SD card

    cat <<EOF > user-data
    #cloud-config
    # vim: syntax=yaml
    
    hostname: master
    manage_etc_hosts: true
    
    # You could modify this for your own user information
    users:
      - name: pirate
        gecos: "Hypriot Pirate"
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        groups: users,docker,video,input
        plain_text_passwd: hypriot
        lock_passwd: false
        ssh_pwauth: true
        chpasswd: { expire: false }
    
    # Upgrade and install packages 
    packages:
      - vim
    package_upgrade: true
    package_reboot_if_required: true
    
    runcmd:
      # Pickup the hostname changes
      - 'systemctl restart avahi-daemon'
    EOF
    flash --hostname <NAME> --userdata user-data https://github.com/hypriot/image-builder-rpi/releases/download/v1.12.3/hypriotos-rpi-v1.12.3.img.zip

If flash does not work, use the following. Adapt the path to the disk appropriately.

    diskutil unmountDisk /dev/disk4 && pv /tmp/hypriotos-rpi-v1.12.3.img | sudo dd of=/dev/disk4 bs=1m
    cp user-data /Volumes/HypriotOS
    # Set hostname
    vim /Volumes/HypriotOS/user-data
    diskutil unmountDisk /dev/disk4

## Install k3s

    k3sup install --user pirate --ssh-key ~/.ssh/… --ip 172.16.42.50
    for i in {1..3}; do k3sup join --user pirate --server-ip 172.16.42.50 --ip 172.16.42.5$i; done


## Label nodes

   kubectl label node -l 'node-role.kubernetes.io/master!=true' node-role.kubernetes.io/worker=true

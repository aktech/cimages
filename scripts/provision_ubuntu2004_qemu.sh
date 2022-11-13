#!/usr/bin/env bash

TEMP_DIR=/tmp/ubuntu-qemu-boot
IMAGE_DIR=$TEMP_DIR/images
CLOUD_IMAGE_URL=https://cloud-images.ubuntu.com/minimal/releases/focal/release/ubuntu-20.04-minimal-cloudimg-amd64.img
IMAGE_NAME=ubuntu-20.04-minimal-cloudimg-amd64.img
CLOUDINIT_DIR=$TEMP_DIR/cloudinitmetadata
DISTRIBUTION=ubuntu20.04

rm -rf $TEMP_DIR

echo "======================================================"
echo "Download Ubuntu 20.04 Cloud Image and resize to 30 Gigs"
echo "======================================================"
mkdir -p $IMAGE_DIR
cd $IMAGE_DIR

curl $CLOUD_IMAGE_URL --output $IMAGE_NAME
qemu-img resize $IMAGE_NAME 30G

echo "======================================================"
echo "Create the cloud-init NoCloud metadata disk file"
echo "======================================================"
mkdir -p $CLOUDINIT_DIR
cd $CLOUDINIT_DIR

echo "======================================================"
echo "Create SSH Keys for the image"
echo "======================================================"
ssh-keygen -b 2048 -t rsa -f id_rsa_ubuntu2004boot -P ""
chmod 0600 $CLOUDINIT_DIR/id_rsa_ubuntu2004boot
PUBLIC_KEY=$(cat id_rsa_ubuntu2004boot.pub)

cat <<EOF >$CLOUDINIT_DIR/meta-data
instance-id: cirun-machine-101
local-hostname: cirun-machine
EOF


cat <<EOF >$CLOUDINIT_DIR/user-data
#cloud-config
debug: true
disable_root: false
users:
  - name: root
    shell: /bin/bash
    ssh-authorized-keys:
      - ${PUBLIC_KEY}
    ssh_import_id:
      - gh:aktech
    sudo: ALL=(ALL) NOPASSWD:ALL
    group: sudo
runcmd:
  - |
    echo "Installing Nvidia Drivers"
    echo "========================="
    echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y -q
    DEBIAN_FRONTEND=noninteractive sudo apt update
    DEBIAN_FRONTEND=noninteractive sudo apt upgrade -y
    DEBIAN_FRONTEND=noninteractive sudo apt install nvidia-driver-460 -y
    echo "Nvidia Drivers Installed!"
    echo "========================="
    echo "Installing Docker"
    echo "========================="
    curl -fsSL https://get.docker.com -o get-docker.sh
    DEBIAN_FRONTEND=noninteractive sudo sh get-docker.sh
    echo "Enable docker"
    echo "========================="
    sudo systemctl --now enable docker
    echo "Distribution: $DISTRIBUTION"
    echo "========================="
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$DISTRIBUTION/libnvidia-container.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    echo "APT Update"
    echo "========================="
    DEBIAN_FRONTEND=noninteractive sudo apt-get update
    echo "Install nvidia-docker2"
    echo "========================="
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y nvidia-docker2
    echo "Restart docker"
    echo "========================="
    DEBIAN_FRONTEND=noninteractive sudo systemctl restart docker
    echo "Shutdown machine"
    sudo shutdown now
    echo "========================="
EOF

echo "Create the cloud-init optical drive"
mkisofs -output cidata.iso -volid cidata -joliet -rock user-data meta-data

echo "Boot the machine up"
qemu-system-x86_64 -m 2048 -smp 4 \
  -hda $IMAGE_DIR/$IMAGE_NAME \
  -cdrom $CLOUDINIT_DIR/cidata.iso \
  -device e1000,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::5555-:22 \
  -nographic

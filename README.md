# Cloud Images

[![Build Image](https://github.com/aktech/cimages/actions/workflows/build.yml/badge.svg)](https://github.com/aktech/cimages/actions/workflows/build.yml)

This loads Ubuntu's cloud image via QEMU and installs the following on top of it via [cloud-init](https://cloudinit.readthedocs.io/en/latest/):

- NVIDIA Drivers
- Docker

More packages can be installed in the base image by modifying the user data script in the
following file:

```
scripts/provision_ubuntu2004_qemu.sh
```

## Setup and Installation

* Install Dependencies and Boot up machine

```
./scripts/install_dependencies.sh
./scripts/provision_ubuntu2004_qemu.sh
```

## SSH into the machine

After the machine has booted and cloudinit is ran, you can ssh into the
machine with the following command:

```
ssh -o "StrictHostKeyChecking no" -p 5555 root@localhost
```

SSH keys can be added by modifying either of the following keys in the user data script in the
provision script (`scripts/provision_ubuntu2004_qemu.sh`).

- `ssh-authorized-keys` (accepts ssh public key)
- `ssh_import_id` (fetches ssh keys from GitHub or launchpad)

See:

- https://cloudinit.readthedocs.io/en/latest/topics/modules.html#ssh-import-id
- https://cloudinit.readthedocs.io/en/latest/topics/modules.html?highlight=ssh-authorized-keys#authorized-keys

For everything else refer to cloud-init docs:
https://cloudinit.readthedocs.io/en/latest/

## Artifact

To achieve the above mentioned, the script downloads the Ubuntu 20.04 image from https://cloud-images.ubuntu.com
After running the script, the downloaded image is modified to include the above mentioned packages via cloud-init,
you can notice the change in size of the image as a result. This image is the final artifact and can be used to spinup
VMs in systems like OpenStack.

## GitHub Actions

The image is built on GitHub Actions and then uploaded to GCP storage.

#!/bin/bash

IMG_NAME="Kinoite for the MSI Stealth 15M"
IMG="ostree-unverified-registry:ghcr.io/sihawken/kinoite-msi-stealth-15m:latest"

if [[ $(id -u) == 0 ]]; then
    echo "Do not run this script using sudo. Please run as a normal user."
    exit 99
fi

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VAR=$VARIANT
fi

# Only run if on Kinoite or Silverblue
if [ "${OS}" = "Fedora Linux" ] && [ "${VAR}" = "Kinoite" ]; then
    echo "System is running Fedora Kinoite. Ready to migrate to: ${IMG_NAME}."
elif [ "${OS}" = "Fedora Linux" ] && [ "${VAR}" = "Silverblue" ]; then
    echo "System is running Fedora Silverblue. Ready to migrate to: ${IMG_NAME}."
else 
    echo "Host system is neither Fedora Silverblue or Fedora Kinoite. This script only supports migrating from these two systems. Please install Fedora Silverblue or Fedora Kinoite and run the script again."
    exit 1
fi

read -r -p "WARNING: Rebasing to ${IMG_NAME} will delete all preinstalled flatpaks. This script is meant to only be used on a new Kinoite or Silverblue install. Do you wish to continue? [y/N]: " migrationresponse
if [[ ! $migrationresponse =~ ^[Yy]$ ]]; then
    echo "Confirmation not recieved. System will not be migrated."
    exit 1
fi

echo "Migrating to ${IMG_NAME}. Running rpm-ostree rebase && setting the kernel arguments."

RUNSCRIPT="RET=1; until [ \${RET} -eq 0 ]; do rpm-ostree rebase --experimental ${IMG}; RET=\$?; if [[ ! \$RET = 0 ]]; then read -r -p 'Rebasing failed. Do you want to try again? [y/N]: ' retryresponse; if [[ ! \$retryresponse =~ ^[Yy]$ ]]; then exit 1; fi; fi; done; rpm-ostree kargs --append=rd.driver.blacklist=nouveau --append=modprobe.blacklist=nouveau --append=nvidia-drm.modeset=1 --append=nvidia.NVreg_DynamicPowerManagement=0x02 --append=nvidia.NVreg_DynamicPowerManagementVideoMemoryThreshold=200"

pkexec /bin/bash -c "${RUNSCRIPT}"


echo "System migrated. Reboot to run the new image."

read -r -p "Do you wish to reboot now? [y/N]: " rebootresponse

if [[ $rebootresponse =~ ^[Yy]$ ]]; then
    echo "Rebooting in 5 seconds..."
    sleep 5
    systemctl reboot
fi
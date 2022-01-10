#!/bin/sh

# DPDK requires that the driver bound to the interface that uses it (the SR-IOV interface in the VM) is vfio-pci.
# This script checks the driver type, and replaces it if needed.
# To run this script - login as root (`sudo su`)


# Find the driver type of the SR-IOV interface.
driver=$(ethtool -i sriov1 | sed -n -e 's/^.*driver: //p')
if [ "$driver" == "vfio-pci" ]
then
  echo "Driver is vfio-pci, no extra action needed."
  exit
fi
echo "driver is $driver"

# Deactivate the NIC to be bound to DPDK.
ip link set down dev sriov1

# Retrieve the de-activated NIC's PCI slot.
pci_addr=$(dpdk-devbind.py --status | grep -v Active | grep 0000 | cut -d ' ' -f 1 | paste -sd ' ')

# Create hugepages mountpoint directory.
mkdir /mnt/huge

# Mount hugepages.
mount /mnt/huge --source nodev -t hugetlbfs -o pagesize=1GB

# Load Required kernel modules.
modprobe vfio enable_unsafe_noiommu_mode=1
modprobe vfio-pci

# Enable unsafe IOMMU.
echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode
echo "options vfio enable_unsafe_noiommu_mode=1" > /etc/modprobe.d/vfio-noiommu.conf

# Bind the DPDK NICs.
dpdk-devbind.py -b vfio-pci $pci_addr


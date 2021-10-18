# Running an Openshift Virtualization VM with SR-IOV and DPDK
Supplied here are methods for running an Openshift Virtualization guest VM supporting SR-IOV, with DPDK in it, in order to run tespmd (DPDK testing tool) on it.


## Creating the base image
- Download a base RHEL image from RHEL download center (https://access.redhat.com/downloads/).
- Copy the downloaded image qcow2 file to any directory you want to work in (the working diectory).
> Note:
>
> This image file is overriden when you create the new image, so you need to place the original image file in the working directory for every attempt to re-create the image.
>
> Make sure you have the original image file stored locally, so you don't have to pull it for every attempt.
- Set RHEL_IMAGE and RHEL_VERSION, .e.g
```bash
export RHEL_IMAGE=rhel-84.qcow2
export RHEL_VERSION=8.4
```
- For creating the image - you must install the following tools:
  cloud-utils
  docker-ce
  virt-install
  qemu-img
```bash
dnf install -y cloud-utils docker-ce virt-install qemu-img
```
- Run
```bash
./build.sh $RHEL_IMAGE $RHEL_VERSION
```
- After the image loads and the VM runs - check that the image is created as you expect it, for example:
 Run "sudo dpdk-testpmd" and verify it runs successfully.
- Exit the image gracefully with
```bash
shutdown -h now".
```
- Tag and push the image:
```bash
# rhel_build is the output directory created by build.sh script
cd rhel_build/
podman load -i rhel-$RHEL_VERSION.tar
podman tag rhel:$RHEL_VERSION <destination repo>:$RHEL_VERSION-dpdk
podman push <destination repo>:$RHEL_VERSION-dpdk
```
* In this example the image was tagged with a new tag $RHEL_VERSION-dpdk (i.e. 8.4-dpdk), so when pushed - it won't override the image in the repo that is already tagged as "8.4".

* Important: If, for some reason, you need to override the result image and create a new one:
 - Remove the image qcow2 file, as it was overriden by the new image, which uses the new name.
 - Remove the image:
  ```bash
  virsh destroy rhel-8.4
  virsh undefine rhel-8.4
  rm -rf rhel_build/ rhel-8.4.qcow2
  ```
 - Copy the original image qcow2 file to the working directory.

* To use this image in a VM spec - reference the image in the VM yaml (a usable VM yaml file exists here in `resource-specs` dir :
```yaml
      - containerDisk:
          image: <destination repo>:$RHEL_VERSION-dpdk
```
 Keep in mind that for debugging - you might need to always pull the latest image, if you modified it. For that - change (or add) the pullPolicy:
```yaml
          imagePullPolicy: Always
```
 You might also need to remove the image from the hosting node (on which the VMI ran), by running
```bash
podman image rm <image ID>
```
 Specifically for RHEL - set `resources.requests.memory` to 4096M. Otherwise, the memory request might not be enough for the VM, which will end in oom (out-of-memory) errors on VM console when it starts.


## Needed SR-IOV Openshift sources for the cluster
If not yet applied - you should apply the SR-IOV network resources:
```bash
oc apply -f SriovNetworkNodePolicy.yaml
```
Few values that need to be set in the policy resource:
1. pfNames: Change according to the name of the PF interface on the hosting node.
2. rootDevices address: The device address of the PF can be retrieved by running
```bash
ethtool -i <PF NIC name>
```
and retrieving the value of 'bus-info'
3. numVfs: Change according to the actual number of VFs configured on the PF.


```bash
oc apply -f SriovNetwork.yaml
```
An example of the VM that can be created based on the above configurations is in this repo:
```bash
oc apply -f sriov-vm1.yaml
```
Note that `containerDisk` value should be replaced with the actual repo where the base image is located.


## Extra steps on the running VM
DPDK requires that the driver bound to the interface that uses it (the SR-IOV interface in the VM) is vfio-pci.
It might be, however, that the driver supported by the node is different. In that case, the user would have to actively replace the default driver (e.g. iavf) which is bound to the SR-IOV NIC in the VM.
You can achieve that by running the scripts/change-nic-driver.sh script in the VM (copy its contents to the VM).
* Note: You should run this script as root user.
```bash
sudo su
```

The steps run by this script are as follows:
1. Find the driver type of the SR-IOV interface.
```bash
[cloud-user@sriov-vm1 ~]$ ethtool -i sriov1
driver: iavf
...
```
The driver is indeed not vfio-pic, therefore it should be replaced.
1. Deactivate the NIC to be bound to DPDK.
```bash
ip link set down dev sriov1
```
2. Retrieve the de-activated NIC's PCI slot.
```bash
dpdk-devbind.py --status | grep -v Active | grep 0000 | cut -d ' ' -f 1 | paste -sd ' '
```
3. Create hugepages mountpoint directory.
```bash
mkdir /mnt/huge
```
4. Mount hugepages.
```bash
mount /mnt/huge --source nodev -t hugetlbfs -o pagesize=1GB
```
5. Load Required kernel modules.
```bash
modprobe vfio enable_unsafe_noiommu_mode=1
modprobe vfio-pci
```
6. Enable unsafe IOMMU.
```bash
echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode
echo "options vfio enable_unsafe_noiommu_mode=1" > /etc/modprobe.d/vfio-noiommu.conf
```
7. Bind the DPDK NICs.
```bash
dpdk-devbind.py -b vfio-pci 0000:06:00.0
```
where 0000:06:00.0 is the NIC's PCI slot address, retrieved earlier.


## Running testpmd
Get the CPUs list:
```bash
lscpu
...
NUMA node0 CPU(s):   0,1

```
```bash
dpdk-testpmd -l 0,1 -w 0000:06:00.0
```

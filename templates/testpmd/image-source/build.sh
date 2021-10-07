#!/usr/bin/env bash
set -xe

BUILD_DIR="rhel_build"
RHEL_IMAGE=$1
CLOUD_INIT_ISO="cidata.iso"
NAME="rhel${RHEL_VERSION}"
mkdir $BUILD_DIR

echo "Create cloud-init user data ISO"
cloud-localds $CLOUD_INIT_ISO user-data

echo "Run the VM (ctrl+] to exit)"
virt-install \
  --memory 4096 \
  --vcpus 2 \
  --name $NAME \
  --disk $RHEL_IMAGE,device=disk \
  --disk $CLOUD_INIT_ISO,device=cdrom \
  --os-type Linux \
  --os-variant $NAME \
  --virt-type kvm \
  --graphics none \
  --network default \
  --import

echo "Remove RHEL VM"
virsh destroy $NAME || :
virsh undefine $NAME

rm -rf $CLOUD_INIT_ISO

echo "Convert image"
qemu-img convert -c -O qcow2 $RHEL_IMAGE $BUILD_DIR/$RHEL_IMAGE

echo "Create Dockerfile"
echo "FROM kubevirt/container-disk-v1alpha" >> $BUILD_DIR/Dockerfile
echo "ADD $RHEL_IMAGE /disk" >> $BUILD_DIR/Dockerfile

pushd $BUILD_DIR
echo "Build docker image"
docker build -t rhel:$RHEL_VERSION .

echo "Save docker image as TAR"
docker save --output rhel-$RHEL_VERSION.tar rhel
popd
echo "RHEL image locate at $BUILD_DIR"

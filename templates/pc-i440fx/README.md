# Overview

This directory provides a generic template, to support legacy guest OS
which require an older pc-i440fx machine type to boot.
Clusters that were deployed using the HyperConverged Operator do not include
support for this machine type. To allow Virtual Machines to request this
machine type, this option should be manually added.

# Update HCO (OpenShift Virtualization >= 4.8)

It is necessary to add the relevant machine type to a list of permitted types.
This will allow Virtual Machines to request the pc-i440fx machine type:

```
$ oc annotate --overwrite -n openshift-cnv hco kubevirt-hyperconverged kubevirt.kubevirt.io/jsonpatch='[{"op": "add", "path": "/spec/configuration/emulatedMachines", "value": ["q35*", "pc-q35*", "pc-i440fx-rhel7.6.0"] }]'

```

# Update KubeVirt Config Map (OpenShift Virtualization 2.6.X)

The add the relevant machine type to a list of permitted types on OpenShift
Virtualization 2.6.X kubevirt-config Config Map should be updated.
Open the kubevirt-config config map for editing by running the following
command:

`$ oc edit configmap kubevirt-config -n openshift-cnv`

Edit the config map:

```
kind: ConfigMap
metadata:
  name: kubevirt-config
data:
  emulated-machines: q35*,pc-q35*,pc-i440fx-rhel7.6.0
```

# Usage

The provided template can be used to create a Virtual Machine:

`$ oc process --local -f templates/pc-i440fx/generic-server-large-pc-i440fx.yaml`


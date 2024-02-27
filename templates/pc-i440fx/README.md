# Overview

This directory provides a generic template, to support legacy guest OS
which require an older pc-i440fx machine type to boot.
Clusters that were deployed using the HyperConverged Operator do not include
support for this machine type. To allow Virtual Machines to request this
machine type, this option should be manually added.

# Update HCO (OpenShift Virtualization >= 4.10)

It is necessary to add the relevant machine type to a list of permitted types.
This will allow Virtual Machines to request the pc-i440fx machine type:

```
$ oc annotate --overwrite -n openshift-cnv hco kubevirt-hyperconverged kubevirt.kubevirt.io/jsonpatch='[{"op": "add", "path": "/spec/configuration/emulatedMachines", "value": ["q35*", "pc-q35*", "pc-i440fx-rhel7.6.0"] }]'

```

# Update HCO (OpenShift Virtualization >= 4.14)

It is necessary to add the relevant machine type to a list of permitted types.
This will allow Virtual Machines to request the pc-i440fx machine type:

```
$ oc annotate --overwrite -n openshift-cnv hco kubevirt-hyperconverged \
  kubevirt.kubevirt.io/jsonpatch='[
  {"op": "add", "path": "/spec/configuration/architectureConfiguration", "value": {} },
  {"op": "add", "path": "/spec/configuration/architectureConfiguration/amd64", "value": {} },
  {"op": "add", "path": "/spec/configuration/architectureConfiguration/amd64/emulatedMachines", "value": ["q35*", "pc-q35*", "pc-i440fx-rhel7.6.0"] } ]'

```

# Usage

The provided template can be used to create a Virtual Machine:

`$ oc process --local -f templates/pc-i440fx/generic-server-large-pc-i440fx.yaml`

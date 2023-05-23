# Overview

This directory provides template, which could be used to run workloads like SAP
HANA on Red Hat OpenShift Virtualization or kubevirt.


# Usage

The provided template can be used to create a Virtual Machine:

`$ oc process --local -f templates/saphana/rhel8.saphana.yaml`

The parameters of the rhel8.sapnetweaver.yaml are required to be filled in the
end of the file. Please find information about running SAP Netweaver on
OpenShift Virtualization in https://access.redhat.com/articles/7013631.

If the template should be available in the graphical UI, it has to be deployed into a custom namespace:

`$ oc create -n default -f templates/saphana/rhel8.saphana.yaml`


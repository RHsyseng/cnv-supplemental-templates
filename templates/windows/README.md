# Overview

This directory provides template, which could be used to run windows workloads like windows server 2k12r2
on Red Hat OpenShift Virtualization or KubeVirt.


# Usage

The provided templates can be used to create a Virtual Machine:

`$ oc process --local -f templates/win2k12/windows2k12r2-<type>.yaml`

The parameters of the `windows2k12r2-<type>.yaml` are required to be filled in the
end of the file.

If the template should be available in the graphical UI, it has to be deployed into a custom namespace:

`$ oc create -n default -f templates/win2k12/windows2k12r2-<type>.yaml`


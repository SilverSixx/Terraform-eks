# modules/eks/templates/userdata.tpl
#!/bin/bash
set -o xtrace

# Bootstrap script for EKS nodes
/etc/eks/bootstrap.sh ${cluster_name} \
  --apiserver-endpoint ${cluster_endpoint} \
  ${bootstrap_extra_args}

# Apply any custom user data scripts
${custom_userdata}
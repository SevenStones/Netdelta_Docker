#!/usr/bin/env bash

YAML_DIR="/home/iantibble/netdd/k8s"

cd ${YAML_DIR} || { echo "k8s YAMLs directory not found"; exit 1; }
echo -e "$('pwd')"
while read pvc; do
  kubectl apply -f $pvc
done < <(ls *-persistentvolumeclaim.yaml)
#sleep 10
#echo "Building file server sidecar"
#kubcetl apply -f file-server-deployment.yaml
#sleep 10

#!/bin/bash

set -ex
set -o pipefail

# We will intercept the kube-dns service
LOCAL_DNS=`kubectl get services -n kube-system kube-dns -o=jsonpath={.spec.clusterIP}`

cat k8s-local-dns.yaml \
  | sed -e s/addonmanager.kubernetes.io/#addonmanager.kubernetes.io/g \
  | sed -e s@kubernetes.io/cluster-service@#kubernetes.io/cluster-service@g \
  | sed s/__PILLAR__LOCAL__DNS__/${LOCAL_DNS}/g \
  | kubectl apply -f -

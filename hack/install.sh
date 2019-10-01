#!/bin/bash

set -ex
set -o pipefail

DEFAULT_LOCALDNS_IMAGE=axot/k8s-dns-local-dns-amd64:v0.0.1-6-ga977ec7

[ -z ${LOCALDNS_IMAGE} ] && LOCALDNS_IMAGE=${DEFAULT_LOCALDNS_IMAGE}

# Create the underlying uncached service
kubectl apply -f kube-dns-uncached.yaml

# We will intercept the kube-dns service
LOCAL_DNS=`kubectl get services -n kube-system kube-dns -o=jsonpath={.spec.clusterIP}`

# And we will forward misses to the uncached service we created above
UPSTREAM_DNS=`kubectl get services -n kube-system kube-dns-uncached -o=jsonpath={.spec.clusterIP}`

# Assume the cluster DNS domain was not changed
DNS_DOMAIN=cluster.local

cat k8s-local-dns.yaml configmap.yaml \
  | sed -e s/addonmanager.kubernetes.io/#addonmanager.kubernetes.io/g \
  | sed -e s@kubernetes.io/cluster-service@#kubernetes.io/cluster-service@g \
  | sed -e 's@k8s-app: kube-dns@k8s-app: local-dns@g' \
  | sed -e s/__PILLAR__LOCAL__DNS__/${LOCAL_DNS}/g \
  | sed -e s/__PILLAR__DNS__SERVER__/${UPSTREAM_DNS}/g \
  | sed -e s/__PILLAR__DNS__DOMAIN__/${DNS_DOMAIN}/g \
  | sed -e s@__LOCALDNS_IMAGE__@${LOCALDNS_IMAGE}@ \
  | kubectl apply -f -

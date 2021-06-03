#!/bin/bash

set -ex
set -o pipefail

DEFAULT_LOCALDNS_IMAGE=colopl/k8s-dns-local-dns-amd64:0.1.0

[ -z ${LOCALDNS_IMAGE} ] && LOCALDNS_IMAGE=${DEFAULT_LOCALDNS_IMAGE}

# check if using coredns or kube-dns, fall back to kube-dns if neither found
CLUSTER_DNS_BACKEND=`kubectl get services -n kube-system | egrep  "^coredns |^kube-dns " | awk '{print $1}' | head -n 1`
if [[ -z $CLUSTER_DNS_BACKEND ]]; then
    CLUSTER_DNS_BACKEND=kube-dns
fi    

# Create the underlying uncached service
sed -i "s/k8s-app: kube-dns/k8s-app: ${CLUSTER_DNS_BACKEND}/g" dns-service-uncached.yaml
sed -i "s/name: kube-dns-uncached/name: ${CLUSTER_DNS_BACKEND}-uncached/g" dns-service-uncached.yaml
kubectl apply -f dns-service-uncached.yaml

# We will intercept the kube-dns service
LOCAL_DNS=`kubectl get services -n kube-system ${CLUSTER_DNS_BACKEND} -o=jsonpath={.spec.clusterIP}`

# And we will forward misses to the uncached service we created above
UPSTREAM_DNS=`kubectl get services -n kube-system ${CLUSTER_DNS_BACKEND}-uncached -o=jsonpath={.spec.clusterIP}`

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

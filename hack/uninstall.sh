#!/bin/bash

set -ex
set -o pipefail

cat configmap.yaml | kubectl delete -f -
cat k8s-local-dns.yaml | kubectl delete -f -
cat kube-dns-uncached.yaml | kubectl delete -f -

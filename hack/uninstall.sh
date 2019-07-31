#!/bin/bash

set -ex
set -o pipefail

cat k8s-local-dns.yaml \
  | kubectl delete -f -

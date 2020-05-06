#!/bin/bash -e
helm package kube-asg-node-drainer
helm repo index --url https://conservis.github.io/kube-asg-node-drainer/ --merge index.yaml .
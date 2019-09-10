#!/bin/bash -e
helm package kube-asg-node-drainer
helm repo index kube-asg-node-drainer/ --url https://conservis.github.io/kube-asg-node-drainer/
mv kube-asg-node-drainer/index.yaml index.yaml

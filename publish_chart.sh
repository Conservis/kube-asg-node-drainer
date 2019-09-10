#!/bin/bash -e
helm package kube-asg-node-drainer
mv kube-asg-node-drainer-1.0.0.tgz kube-asg-node-drainer
helm repo index kube-asg-node-drainer/ --url https://conservis.github.io/kube-asg-node-drainer/

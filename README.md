## AWS ASG rebalancing node drainer

### 1. Why 
A workaround for rebalancing feature of ASG https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#common-notes-and-gotchas. 
More in https://chrisdodds.net/kubernetes-ec2-autoscaling-for-fun-and-profit/ on why the official "fix" sucks. 

### 2. What

* Based on [kube-aws deployment](https://github.com/kubernetes-incubator/kube-aws/blob/2f7e360421bc32c839e1acd31e8d0f082dfdab1e/builtin/files/userdata/cloud-config-controller#L1104) and [kube-aws resources](https://github.com/kubernetes-incubator/kube-aws/blob/2f7e360421bc32c839e1acd31e8d0f082dfdab1e/builtin/files/userdata/cloud-config-controller#L2658).
* Transformed into a helm chart to be effectively used in any EKS cluster.
* The final solution gracefully evicts pods - even single replicas or deployments without PDB - with `kubectl rollout restart`.

### 3. Prerequisites - AWS InfraStructure Setup

ASG must provide a lifecycle hook `kube-asg-node-drainer` to let the node drainer script notify ASG after completing the POD eviction:

```
aws cloudformation deploy --template-file cf/lifecyclehook.yml --stack-name kube-asg-node-drainer-hook --parameter-overrides AsgName=<YOUR_ASG_NAME>
```

This chart assumes that the worker node is provided with an IAM role to access ASG resources:
```
aws cloudformation deploy --template-file cf/noderole.yml --stack-name kube-asg-node-worker-role
```

If a project uses [kube2iam](https://github.com/jtblin/kube2iam) one can use `iamRole` in `values.yml` to assign an IAM Role to the `kube-asg-node-drainer` pods.

### 4. Install

`kube-asg-node-drainer` release must be installed to `kube-system` namespace: pods with system-node-critical priorityClass are not permitted in any other space.

Option 1:

```
helm upgrade --install --namespace kube-system kube-asg-node-drainer https://conservis.github.io/kube-asg-node-drainer/kube-asg-node-drainer-<version>.tgz
```

Option 2: 

```
helm repo add conservis https://conservis.github.io/kube-asg-node-drainer/
helm install --name kube-asg-node-drainer --namespace kube-system conservis/kube-asg-node-drainer
```

| kube-asg-node-drainer version  | Kubernetes versions             | 
|--------------------------------|---------------------------------|
| 1.0.x                          | 1.15.x - 1.12.x                 |
| 1.16.x                         | 1.16.x                          |


### 5. Test
How to test that things work:
* terminate an instance in the desired ASG
```bash
aws autoscaling terminate-instance-in-auto-scaling-group --no-should-decrement-desired-capacity --instance-id <instance-id>
```
* the instance/node is marked with `Terminating:Wait`
* `kube-asg-node-drainer` will start gracefully evicting the pods
* autoscaler replaces the node `instance-id` with the new one
* pods move from terminating instances to new ones

During that period one can verify that the app didn't go down by something like:

```bash
while true; do date; curl <app_health_check>; echo ''; sleep 5; done

```

### History

https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws#common-notes-and-gotchas, third comment:

```
On creation time, the ASG will have the AZRebalance process enabled, which means it will actively work 
to balance the number of instances between AZs, and possibly terminate instances. If your applications 
could be impacted from sudden termination, you can either suspend the AZRebalance feature, or use a tool 
for automatic draining upon ASG scale-in such as the [k8s-node-drainer]https://github.com/aws-samples/amazon-k8s-node-drainer.
```


As of 2020-05-22 known workaround solutions are:
* [AWS Lambda](https://github.com/aws-samples/amazon-k8s-node-drainer) solution
* [Custom daemonset](https://github.com/kubernetes-incubator/kube-aws/blob/master/builtin/files/userdata/cloud-config-controller#L2671)
* https://github.com/rebuy-de/node-drainer

Any of this solution will face the issue while draining node/evicting a pod in a single-replica deployment and there still will be downtime to the app. PodDisruptionBudget won’t help in this case because of https://github.com/kubernetes/kubernetes/issues/66811. This limitation is best described in https://github.com/kubernetes/kubernetes/issues/66811#issuecomment-517219951. 

Bottom line: As of today (2020-05-22) the best solution we can provide is:

* cordon the node - `kubectl cordon <node>`
* trigger restart for pods requiring graceful eviction - `kubectl rollout restart deployment/<deployment_name>`

## AWS ASG rebalancing node drainer

### Why 
A workaround for rebalancing feature of ASG https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#common-notes-and-gotchas. 
More in https://chrisdodds.net/kubernetes-ec2-autoscaling-for-fun-and-profit/ on why the official "fix" sucks. 

### What

* Based on [kube-aws deployment](https://github.com/kubernetes-incubator/kube-aws/blob/2f7e360421bc32c839e1acd31e8d0f082dfdab1e/builtin/files/userdata/cloud-config-controller#L1104) and [kube-aws resources](https://github.com/kubernetes-incubator/kube-aws/blob/2f7e360421bc32c839e1acd31e8d0f082dfdab1e/builtin/files/userdata/cloud-config-controller#L2658).
* Transformed into a helm chart to be effectively used in any EKS cluster.
* The final solution gracefully evicts pods - even single replicas or deployments without PDB - with `kubectl rollout restart`.

### AWS InfraStructure Setup

ASG must provide a lifecycle hook `kube-asg-node-drainer` to let the node drainer script complete the POD eviction:

```
aws cloudformation deploy --template-file cf/lifecyclehook.yml --stack-name kube-asg-node-drainer-hook --parameter-overrides AsgName=<YOUR_ASG_NAME>
```

This chart assumes that the worker node is provided with an IAM role to access ASG resources:
```
aws cloudformation deploy --template-file cf/noderole.yml --stack-name kube-asg-node-worker-role
```

If a project uses [kube2iam](https://github.com/jtblin/kube2iam) one can use `iamRole` in `values.yml` to assign an IAM Role to the `kube-asg-node-drainer` pods.

### Install



### History

https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws#common-notes-and-gotchas, second notice:

```
Cluster autoscaler does not support Auto Scaling Groups which span multiple Availability Zones;
instead you should use an Auto Scaling Group for each Availability Zone and enable the --balance-similar-node-groups feature. 
If you do use a single Auto Scaling Group that spans multiple Availability Zones 
you will find that AWS unexpectedly terminates nodes without them being drained because of the rebalancing feature.
```

The official approach is kind of ugly and introduces more scaling and load-balancer complexity on the AWS side and is considered suboptimal. 

Another approach is to have a life cycle hook which drains the nodes once the rebalancing occurs:
* [AWS Lambda](https://github.com/aws-samples/amazon-k8s-node-drainer) solution
* [Custom daemonset](https://github.com/kubernetes-incubator/kube-aws/blob/2f7e360421bc32c839e1acd31e8d0f082dfdab1e/builtin/files/userdata/cloud-config-controller#L2658)

Any of this solution will face the issue with draining node/evicting a pod because if a deployment has a single replica there still will be downtime to the app. PodDisruptionBudget won’t help in this case because of https://github.com/kubernetes/kubernetes/issues/66811. This limitation is best described in https://github.com/kubernetes/kubernetes/issues/66811#issuecomment-517219951. 

Bottom line: As of today (August 20, 2019) the best solution we can provide is:

* cordon the node - `kubectl cordon <node>`
* trigger restart for pods requiring graceful eviction - `kubectl rollout restart deployment/<deployment_name>`

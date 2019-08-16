# Pod scheduling

1. Resource requests
2. [Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
3. [Node selector](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)
4. [Affinity](https://docs.openshift.com/container-platform/3.6/admin_guide/scheduling/pod_affinity.html)

## Getting started

Before you get started with this workshop, you will need to have a Cluster with some default nodes, ideally without any taints.
You will need to create the cluster resources we will be working with by applying `deploy.yaml`, make sure to run:

> kubectl apply -f deploy.yaml

This will create a number of pods, services and other resources required to get started.

## Resource requests

K8s leverages resource requests for many different aspects, including scheduling, auto-scaling and pod preemption. It is best practice to have these configured for all your pods([see best practices video](https://www.youtube.com/watch?v=xjpHggHKm78)). Deciding on which value to set for the request depends entirely on the container being deployed. See [this](https://opensource.com/article/18/12/optimizing-kubernetes-resource-allocation-production) blog about determineing resource requests and limits for your containers.

1. Given the deployment `webserver`, determine appropriate resource requests

As k8s cluster admin, it is good practice to [enforce resource requests per namespace](https://kubernetes.io/docs/concepts/policy/limit-range/) in case users forget to set them.

2. Set resource request default values at the namespace level

3. Set resource request limitations per namespace

Setting limits works in basically the same way as setting requests. Note that resource limits do not affect pod scheduling, it is used to ensure your containers do not consume too much CPU or memory and is good practice to use.


## Taints and Tolerations

Taints and tolerations always work together. Taints apply to nodes and tolerations are configured in your pod spec.
To get a better understanding of how this works, we'll start by creating new nodes (now node pool in GKE) and taint the nodes. (If you are using GKE, you can taint the entire node pool during node pool creation)
You can apply a taint to a node manually using this command:

> kubectl taint nodes [node_name] key=value:effect

The defined key and value can be anything you want to use, just make sure to keep note of it. The effect will normally be `NoSchedule`, make sure to review the `PreferredNoSchedule` and the `Execute` effects as well.

You can view the taints on your nodes by describing the nodes themselves using `kubectl describe no`.
If done correctly, you should notice no pods are being scheduled on your nodes with the exception of certain daemonset pods (DaemonSets include certain tolerations by default).
To view the pods and which nodes they are on, use `kubectl get po -n scheduling -o wide`. You can also describe the nodes you've tainted to see which pods have been scheduled there.

Next, we want to allow certain pods to have the ability to ignore the taint and schedule on these tainted nodes.
The `special` deployment needs to have the ability to schedule anywhere, including the tainted nodes. Edit the deployment and add a toleration to it. 
Note that the tolration must match exactly the taint you previously assigned to the node.

To add a toleration to the pods, edit the deployment and add the field `spec.template.spec.tolerations`. For more information on the required fields for a toleration, use `kubectl explain deploy.spec.template.spec.tolerations` or check the k8s API reference doc.

The deployment will perform a rolling update, creating new pods in the process which can now be scheduled on the tainted nodes.

#### Note
Pods will not necessarily be scheduled on the tainted nodes, this step just allows them to be. If no pods were added to the tainted nodes, scale up the deployment (`kubectl scale deploy special replicas=[desired number of pods]`) until pods appear on the tainted node


## Node Selector

Taints prevent unwanted pods to schedule on specific nodes, this is good if certain nodes have limited or more costly resources and you don't want to waste the node's resources.
Alternatively, we can use Node Selector to ensure that your pod is scheduled on a specific node or group of nodes.

Node Selector relies on node labels. Nodes have some labels built in by default, you can view these using `kubectl describe no [node_name] | grep Labels -A 15`.
You can also manually add specific labels to a node; GKE allows you to assign node labels for an entire node pool, otherwise, you can assign a label to a node manually using `kubectl label no [node_name] key=value`.
Node Selector will work with either built-in labels or custom labels. Please update the nodes you previously tainted with a common label (you choose the key=value, ensure that it is consistent).

Next, we'll update the `special` deployment to use Node Selector matching the labels we assigned to the nodes.
Edit the deployment and add the `spec.template.spec.nodeSelector` field.

Once completed, you should see that all of the new pods are now scheduled on the appropriate nodes. If you have any unschedulable pods, review the nodeSelector and node lables you set and make sure they match.

#### Note
Node Selector will evaluate each node and will select amoung the nodes that evaluate to TRUE. Because of this, Node Selector does not provide any kind of flexibility. This is where Node Affinity comes in which is addressed in the next section.


## Affinity

Affinity provides more flexibility than Node Selector both by allowing it to evaluate possible nodes either with a firm boolean (true/false) or by assigning weight to the nodes for the scheduler's algorithm. It also has the ability to evaluate both node labels and pod labels.
As such, affinity can be broken down into 3 parts:

1. Node Affinity
2. Pod Affinity
3. Pod Anti-affinity


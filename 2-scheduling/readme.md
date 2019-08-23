# Pod scheduling

1. Resource requests
2. [Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
3. [Node selector](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)
4. [Affinity](https://docs.openshift.com/container-platform/3.6/admin_guide/scheduling/pod_affinity.html)

## Getting started

Before you get started with this workshop, you will need to have a Cluster with some default nodes, ideally without any taints.
You will need to create the cluster resources we will be working with by applying `deploy.yaml`, make sure to run:

`kubectl apply -f deploy.yaml`

This will create a number of pods, services and other resources required to get started.

## Resource requests

K8s leverages resource requests for many different aspects, including scheduling, auto-scaling and pod preemption. It is best practice to have these configured for all your pods([see best practices video](https://www.youtube.com/watch?v=xjpHggHKm78)). 
Deciding on which value to set for the request depends entirely on the container being deployed. See [this](https://opensource.com/article/18/12/optimizing-kubernetes-resource-allocation-production) blog about determining resource requests and limits for your containers.
it is also worth noting that the resource requests are defined at the container level, not the pod level. If you have multiple containers in a pod, each can (and should) have their resources defined. The pod's total resource requests will be used for scheduling.

1. Given the deployment `webserver`, determine appropriate resource requests.
Once you've established what your requested resources should be, edit the deployment and add the `spec.template.spec.containers[].resources.requests` field. 

As k8s cluster admin, it is good practice to [enforce resource requests per namespace](https://kubernetes.io/docs/concepts/policy/limit-range/) in case users forget to set them.

2. Set resource request default values at the namespace level
Apply a default resource request and limit value for the `scheduling` namespace

3. Set resource request limitations per namespace
Enforce memory and CPU constraints in the `scheduling` namespace to ensure that no pod requests more than 500mb and 250m.
Now that there are constraints and default values set, clear all the pods from the namespace so that the rules get applied to your pods

`kubectl delete po --all -n scheduling`

Setting limits works in basically the same way as setting requests. Note that resource limits do not affect pod scheduling, it is used to ensure your containers do not consume too much CPU or memory and is good practice to use.


## Taints and Tolerations

Taints and tolerations always work together. Taints apply to nodes and tolerations are configured in your pod spec.
To get a better understanding of how this works, we'll start by creating new nodes (new node pool in GKE) and taint the nodes. 
NOTE If you are using GKE, you can taint the entire node pool during node pool creation
You can apply a taint to a node manually using this command:

`kubectl taint nodes [node_name] [key]=[value]:[effect]`

The defined key and value can be anything you want to use, just make sure to keep note of it. The effect will normally be `NoSchedule`, make sure to review the `PreferredNoSchedule` and the `Execute` effects as well.

You can view the taints on your nodes by describing the nodes themselves using `kubectl describe no [node name]`. \n
If done correctly, you should notice no pods are being scheduled on your nodes with the exception of certain daemonset pods ([DaemonSets include certain tolerations by default](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/#taints-and-tolerations)). \n
To view the pods and which nodes they are on, use `kubectl get po -n scheduling -o wide`. You can also describe the nodes you've tainted to see which pods have been scheduled there.

Next, we want to allow certain pods to have the ability to ignore the taint and schedule on these tainted nodes.
The `special` deployment needs to have the ability to schedule anywhere, including the tainted nodes. Edit the deployment and add a toleration to it. 
Note that the tolration must match exactly the taint you previously assigned to the node.

To add a toleration to the pods, edit the deployment and add the field `spec.template.spec.tolerations`. For more information on the required fields for a toleration, use `kubectl explain deploy.spec.template.spec.tolerations` or check the k8s API reference doc.

The deployment will perform a rolling update, creating new pods in the process which can now be scheduled on the tainted nodes.

#### Note
Pods will not necessarily be scheduled on the tainted nodes, this step just allows them to be. If no pods were added to the tainted nodes, scale up the deployment (`kubectl scale deploy special -n scheduling replicas=[desired number of pods]`) until pods appear on the tainted node


## Node Selector

Taints prevent unwanted pods to schedule on specific nodes, this is good if certain nodes have limited or more costly resources and you don't want to waste the node's resources.
Alternatively, we can use Node Selector to ensure that your pod is scheduled on a specific node or group of nodes.

Node Selector relies on node labels. Nodes have some labels built in by default, you can view these using `kubectl describe no [node_name] | grep Labels -A 15`.
You can also manually add specific labels to a node; GKE allows you to assign node labels for an entire node pool, otherwise, you can assign a label to a node manually using `kubectl label no [node_name] [key]=[value]`. \n
Node Selector will work with either built-in labels or custom labels. Please update the nodes you previously tainted with a common label (you choose the key=value, ensure that it is consistent).

Next, we'll update the `special` deployment to use Node Selector matching the labels we assigned to the nodes.
Edit the deployment and add the `spec.template.spec.nodeSelector` field.

Once completed, you should see that all of the new pods are now scheduled on the appropriate nodes. If you have any unschedulable pods, review the nodeSelector and node lables you set and make sure they match.

#### Note
Node Selector will evaluate each node and will select amoung the nodes that evaluate to TRUE. Because of this, Node Selector does not provide any kind of flexibility. This is where Node Affinity comes in which is addressed in the next section.


## Affinity

Affinity provides more flexibility than Node Selector both by allowing it to evaluate possible nodes either with a firm boolean (true/false) or by assigning weight to the nodes for the scheduler's algorithm. It also has the ability to evaluate both node labels and pod labels.
As such, affinity can be broken down into 3 parts:

#### 1. Node Affinity
Like node selector, this evaluates each node against the affinity values set based on labels and tries to choose the node that has the best fit with the requirements.

#### 2. Pod Affinity
Similar to Node affinity. This will decide which node to schedule the pod to by evaluating the labels of each pod that is already scheduled on the node. This feature is used when you have pods that work best when they share a host but you don't want to predefine which nodes will be used or if two workloads need to share a common resource (like a persistent disk)

#### 3. Pod Anti-affinity
This also evaluates nodes based on the pod labels of pods already present on the node. Unlike the previous two affinities, nodes that meet the requirements will be less likely to be used or completely ignored, based on the affinity values. This is useful to ensure that certain pods are not scheduled together such as ensuring an even workload spread or ensuring that two resource intensive pods do not share a common node.



Whether it is Pod or Node affinity, the affinity configuration will be almost identical. The differences in the affinity types have more to do with the level of the resources you want to evaluate (node labels Vs pod labels)

The first value to define for affinity is whether the rules are a strict pass/fail or a suggestion, the two options are:

- `requiredDuringSchedulingIgnoredDuringExecution:` This value is a strict pass/fail evalaution. If no nodes meet the requirements defined in the affinity, the pods won't be scheduled at al.
- `preferredDuringSchedulingIgnoredDuringExecution:` This is more of a suggestion for the scheduler, a preference. When using this option, you will include a weight to your affinity definition. Each time a node evaluation meets the values you set, the defined weight is added to the node for the schedulers final calculations. Even though a node may meet all the desired requirements, this does not mean your pods will definitely be scheduled here, it just means it is more likely. The higher the weight value, the more likely.

If you choose the `preferredDuringSchedulingIgnoredDuringExecution`, your next step is to define a weight to the config. The weight must be an integer. The higher the value, the more importance the evaluation will be.

The rest of the affinity spec will be the same for any of the above choices. 
You will define matching expressions or labelSelector to define the labels you want to evaluate against.

Pod Affinity and anti-affinity have two additional fields that node affinity does not:

- `namespace` will define which namespace to use when verifying pod labels.
- `topologyKey` is a bit more complicated but also defines the scope of the search. You can set the topology to the node level so each node is evaluated on it's own, it can be set to the zone level so all the nodes in a single zone are evalauted together, or at the regional level.

#### Note
If your topologyKey scope is larger than your clusters, it will have the effect of being cluster wide. IE if you have a zonal cluster (all nodes reside in a single zone) and you use the zonal scope for the topologyKey value, all the nodes in your cluster will be evaluated together. This may likely lead to unintended results.


### Example

For this portion, we will skip the Node Affinity since it will work similar to the Node selector used in the previous section.

#### Affinity

There is a deployment called `pressure` that applies load to the `webserver` pods. To reduce network traffic between nodes, we'd like to have these pods scheduled on nodes that also have `webserver` pods running.
Edit the `pressure` deployment and add the `spec.template.spec.affinity` block to it. We will be using podAffinity. We also don't need this as a hard requirement, we don't want to cause scheduling issues. The affinity block will look something like this:

<pre>
...
  template:
    spec:
      affinity:
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            weight: 80
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  values: 
                  - webserver
                  operator: In
              topologyKey: kubernetes.io/hostname
</pre>

Let's review the above:

1. `preferredDuringSchedulingIgnoredDuringExecution` means that this is a preference, not a hard requirement
2. We have to define the `weight` field with an integer, the higher the value, the more these matches are worth when the scheduler makes its decisions
3. The `matchExpressions` works the same as with services and other label matching but with a good deal of flexibility. 
- There can be multiple entries of labels to match against, each new expression is ANDed
- You can define a single key, but allow for multiple different values
- the operator field allows you to define the logic being used, instead of matching certain values to the key, you can create an exclusion list of values
4. The `topologyKey` is set to hostname so each node is evaluated individually

Depending on the size of your nodes and your cluster, this update may not have any direct visible impact. 
Let's try to highlight the impact by tweaking our deployments.

1. Scale down the webserver deployment

`kubectl scale deploy webserver --replicas 1 -n scheduling`

2. Note, affinity only applies during scheduling, so let's force the pods to reschedule

`kubectl delete po --all -n scheduling`

3. Now, once the pods are scheduled, we should see the `pressure` pods grouping as much as possible with the `webserver` pods

`kubectl get po -n scheduling -o wide`

#### Anti-Affinity

Now we need to scale the `webserver` deployment back up but we want to make sure we have a distributed workloads in case one or more nodes go down.
We want to leverage anti-affinity to make sure that each of the pods are scheduled on different nodes.
The Anti-affinity blok will look very similar to the previous affinity block, though we are making some changes.

<pre>
...
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            labelSelector:
              matchExpressions:
              - key: app 
                operator: In
                value:
                - webserver
              topologyKey: kubernetes.io/hostname
</pre>

Notice this time we used `podAntiAffinity` instead of `podAffinity`.
We also used `requiredDuringSchedulingIgnoredDuringExecution` which means the rule must be followed. If no node matches these requirements, the pod will not be scheduled.
Edit the `webserver` deployment and add the above affinity block to it.
Now let's scale up the deployment. 

`kubectl scale deploy -n scheduling webserver --replicas 5`

You should see each of your pods on a different node. If you have less than 5 nodes, not all the pods will be scheduled which would trigger auto-scaling if you have it enabled.
If you have more than 5 or more nodes, all your pods should be scheduled on a different node. This is similar to a daemonset only it does not force a 1:1 ration between nodes and pods, you'll get as many pods as you asked for.

Let's change the topologyKey now to zonal and see what happens.

<pre>
kubectl patch deploy webserver -n scheduling -p \
'{"spec":{"template":{"spec":{"affinty":{"podAntiAffinity": \
{"requiredDuringSchedulingIgnoredDuringExecution": \
{"topologyKey": "failure-domain.beta.kubernetes.io/zone"}}}}}}}'
</pre>

If your cluster is in a single zone, you should only see a single pod due to the topologyKey. If the cluster spans multiple zones, you should have as many pods as there are zones.

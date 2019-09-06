# Auto-scaling in GKE

With the exception of Horizontal Pod Autoscaling, these are all GKE specific features and will require you to use a GKE cluster to follow along. 
For the sake of this tutorial, I recommend starting with a standard default cluster.

1. Node Pool Auto-scaling
2. Node Auto-Provisionning
3. Horizontal Pod Auto-scaling
4. Vertical Pod Auto-scaling

## Cluster level auto-scaling

The first two types of auto-scaling occur at the Cluster level and allows your k8s cluster to add or remove hardware resources to meet the demands of fluctuating workloads. 
Both Node Pool Auto-Scaling and Node Auto Provisioning rely on resource requests configured in your containers. Without these values, the auto-scalers can't properly function.

### 1. Node Pool Auto-Scaling

Node Pool auto-scaling allows you to define a minimum and maximum number of nodes that the node pool can contain. These options are set at the node pool level and means that you can set different values per pool depending on your needs. 
Some node pools might contain static workloads so scaling isn't necesasry while a second node pool may be used for batch jobs and should only scale up on demand.

In more common use cases, the Node Pool Auto-Scaling will be set to ensure that there is always sufficient resources available to the cluster when new workloads (pods) are required. 
The auto-scaler waits until there are unschedulable, examines the node pools with auto-scaling enabled and then determines whether adding a new node will result in the pod being scheduled. 
This means that the scale up action is only considered when a pod is unschedulable. Workloads that exceed their requests that may lead to OOM or CPU pressure on the node will not directly cause the auto-scaler to trigger.

You can enable Node Pool Auto-Scaling at the node pool level either during node pool creation or by updating it. This can be done through the GUI by editing the Node Pool or by using the following command from the command line:

    gcloud container clusters update [cluster_name] --node-pool [node_pool_name] --enable-autoscaling --min-nodes [num_nodes] --max-nodes [num_nodes]

Make sure that you have enough GCE resource quotas to handle the max number of nodes selected. 
For the following examples, set the min to 2 and the max to 6 

As soon as the update completes, the auto-scaler logic will kick in. If you have under utilized nodes, you may notice your cluster size begin to shrink.

To highlight the Node Pool Auto-scaling functionality, deploy the `node-scaling.yaml` 

    kubectl apply -f node-scaling.yaml

If creating this deployment does not trigger a scale up action, add more pods by scaling up the deployment

    kubectl scale deploy -n scaling scalable-workload --replicas 50

This should cause the cluster to reach the maximum of 6 nodes, even though there are still unschedulable pods. 
During the process, you can also view the auto-scaler confiMap to see the status and actions taken by the auto-scaler.

    kubectl describe cm -n kube-system cluster-autoscaler-status

The scale up process should happen pretty quickly, once a pod is unschedulable, the auto-scaler should detect it and scale up a new node. 
The scale down process, however, takes longer to detect. To scale down, we need to make sure the nodes are under utilized, so we'll scale down the deployment to 1. Describe the configMap periodically to watch the auto-scaler's logic.

    kubectl scale deploy -n scaling scalable-workload --replicas 4


### 2. Node Auto-Provisionning

The node pool auto-scaler will increase the number of nodes available using the same node template as the pool. Whateveryou've selected as a machine type will continue being used. 
In contrast, Node Auto-Provisioning (NAP) will add an entirely new node pool to the cluster, it will determine the correct machine type to use to ensure that the new nodes accomodate the workloads you are adding. This is especially useful when using Vertical Pod Auto-scaling (section 4). 

Make sure to review the [GCP public docs for more details](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-provisioning) on NAP. We won't be covering all the different criteria that can trigger NAP to create new nodes, the document will provide you more details.  
Start by enabling NAP on your cluster:

    gcloud beta container clusters update [CLUSTER_NAME] --enable-autoprovisioning --max-cpu [num] --max-memory [num]

Let's take a closer look at the two key flags:
- `--max-cpu` defines the maximum number of CPU coress your cluster can use. This includes any CPU currently in use as well as any CPU used by future nodes due to the Node Pool Auto-Scaler. 
- `--max-memory` defines how much RAM in Gb you are willing to assign to your cluster. 

    NOTE you can also specify GPU types and number of GPUs

Based on the above, note that NAP takes more planning to put into place than the Node Pool Auto-Scaler. You need to calculate how many resources are currently in use, how many may be used by auto-scaling and then determine how much more you are willing to assign to new nodes for NAP to use. 

Let's use our current cluster as an example:
- The default standard cluster will use nodes with 1 CPU and 3.75GB of memory
- The maximum number of nodes in the current node pool is 6
- We want to allow up to an addition 10 cores and 40Gb of memory

The cluster will use 6 CPU and 22.5GB if memory if it gets to 6 nodes. To handle the additional cap for NAP, we'll use `--max-cpu 16 --max-memory 62.5` as the flags for the above command. 
Once the update is complete, create the `bigload` deployment to highlight NAP functionality which should create a new node pool to accomadate the larger requests.

    kubectl apply -f bigload.yaml  

    NOTE: When you enable NAP, there is the option to use the `--autoprovisioning-scopes` flag to set the scopes of the node pool. NAP node pools will not automatically use the same scopes as the rest of your cluster.

NAP can also provision new nodes with node labels to allow for pods with node selector or node affinity enabled to be scheduled:

    kubectl apply -f selective-pods.yaml  

If you delete the two last deployments, NAP should scale down the cluster

    kubectl delete deploy -n scaling -l app=nap


## Pod level Auto-Scaling

### 3. Horizontal Pod Auto-scaling

Horizontal Pod Aut-scaling (HPA) is a kubernetes feature that allows your replicasets to scale up or down based on the resource usage of the pods controlled by the replicaset. The built in functionality only works with CPU utilization (which relies on current CPU usage Vs CPU requested) or custom metrics (Which are reaw values). Read more about HPA and the algorythm it uses [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/). 

To use HPA, you must create an HPA resource in your cluster. Each HPA will target a single resource (normally this will be a Deployment). 
To demonstrate, we'll create an HPA for the `scalable-workload` deployment which should be at 4 replicas. 
First, we'll define the HPA:

<pre>
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: scalable-workload-hpa
  namespace: scaling
spec:
  maxReplicas: 20
  minReplicas: 2
  targetCPUUtilizationPercentage: 75
  scaleTargetRef:
    kind: Deployment
    name: scalable-workload
</pre>

- `minReplicas` and `maxReplicas` are integers and define the minimum and maximum number of pods HPA can set
- `targetCPUUtilizationPercentage` is a percentage of CPU usage determine by (cpu usage/cpu requests) averaged across all pods. HPA will predict how mant replicas are required to be as close to this target as possible while within the limits defined.
- `scaleTargetRef` defines which resource will be scaled (normally a Deployment, but can also be a replicaSet or replicationController)

Currently, the deployment should still have 4 pods and these pods should be severely under utilized. After applying this config, we should see the number of pods drop down to 2 (the minimum number of replicas allowed)

    kubectl apply -f hpa.yaml

If we were to add content to the website and apply heavy load to it, we should eventually see it scale back up. 
NOTE: If HPA is not scaling up your pods in a desired way, you may need to tweak the target usage value in the HPA and modify the CPU requests in your deployment.

As mentioned, you can also define HPA to work with custom metrics. As an example, follow [this guide](https://cloud.google.com/kubernetes-engine/docs/tutorials/custom-metrics-autoscaling)


### 4. Vertical Pod Auto-scaling

Vertical Pod Auto-scaling is a GKE feature that helps with configuring the resource requests of your deployments. From the [Google help doc](https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler):

    Vertical pod autoscaling (VPA) frees you from having to think about what values to specify for a container's CPU and memory requests. The autoscaler can recommend values for CPU and memory requests, or it can automatically update values for CPU and memory requests.

Before using VPA, the feature must be enabled for your cluster. If you are creating a new cluster or this, use the `--enable-vertical-pod-autoscaling` flag or select Vertical Pod Auto-scaling in the UI. FOr existing clusters, use: 

    gcloud beta container clusters update [CLUSTER-NAME] --enable-vertical-pod-autoscaling

Much like HPA, VPA is a resource created within the cluster that targets a specific object (such as a Deployment, DaemonSet, StatefulSet). The VPA will collect data on the running pods that are part of the controller and make recommendations for CPU and Memory requests based on pod performance. 
The VPA resource will look somethig like this:

<pre>
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: my-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       my-deployment ##This is the name of the deployment you want VPA to target
  updatePolicy:
    updateMode: "Off"
</pre>

- The `targetRef` section is used to define which resource you want VPA to target and marches a single resource.
- `updateMode` determines whether VPA will update the resource requests automatically. Setting this value to `Auto` will allow VPA to automatically make changes whichi will trigger pods to be recreated. Setting this value to `Off` allows you to view recommendations without VPA taking any action.

We have two over utilized deployemnts, so we'll apply VPA to both the `large-pods` and the `scalable-workload` deployments. 
Apply the manifest for VPA:

    kubectl apply -f vpa.yaml

The VPA needs time to collect data about the running pods and should eventually decide that the requests configured are too high. The VPA should update the Deployment which will trigger a rolling update of the pods. 
The new pods with lower requests should then also cause the cluster to scale down since the previous requests artifically triggered the cluster to scale. 

Note that VPA will recommend or set requests even if none were set previously. VPA may also modify the requests to a point where the pods will no longer fit on any current nodes, as such it is recommended to enable NAP


# Auto-scaling in GKE

With the exception of Horizontal Pod Autoscaling, these are all GKE specific features and will require you to use a GKE cluster to follow along. 
For the sake of this tutorial, I recommend starting with a standard default cluster.

1. Node Pool auto-scaling
2. Node Auto provisionning
3. Horizontal Pod Auto-scaling
4. Vertical pod Auto-scaling

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

`gcloud container clusters update [cluster_name] --node-pool [node_pool_name] --enable-autoscaling --min-nodes [num_nodes] --max-nodes [num_nodes]`

Make sure that you have enough GCE resource quotas to handle the max number of nodes selected. 
For the following examples, set the min to 2 and the max to 6 

As soon as the update completes, the auto-scaler logic will kick in. If you have under utilized nodes, you may notice your cluster size begin to shrink.

To highlight the Node Pool Auto-scaling functionality, deploy the `node-scaling.yaml` 

`kubectl apply -f node-scaling.yaml`

If creating this deployment does not trigger a scale up action, add more pods by scaling up the deployment

`kubectl scale deploy  --replicas 50`

This should cause the cluster to reach the maximum of 6 nodes, even though there are still unschedulable pods

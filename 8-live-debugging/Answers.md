GKE specific

0. Using the GUI, click on the failed cluster, you should see an error message that indicates why the cluster failed.
The default pod range for a cluster is in 10.0.0.0/8 which is used if you do not define a custom Pod CIDR. In this VPC, that IP range is already in use

1. The pod CIDR is /23. Each node is using the default range of /24 (notice the “110 pods per node”). This means there is only enough IP space to allow for 2 nodes. To avoid this, use a larger pod CIDR or allow fewer pods per node

2. Master Authorised Networks is enabled. By default, this allows the CIDR of the subnet where your cluster is created and that is all. Notice that there is only one external IP that has been added, this is the IP of my bastion VM in my project, not the workstation I am using in the office, thus it will not work.

3. The bastion host and the Mongoose cluster are in different networks; even if peering or a VPN is configured, I can’t reach the master IP from another network.  
    NOTE: This is due to a current limiation with transient route sharing. This issue may be addressed in the future

4. My “Bigjob” pod is asking for 1.5 vCPUs. The nodes in the default pool only have 1 vCPU so pods can’t fit there. The pool with bigger nodes does not have autoscaling. The autoscaler knows that even if it did scale up, the new nodes would not be big enough.

5. Network Policy is enabled on the cluster. There is also a network policy in place in the `api` namespace that is blocking egress traffic

6. The nodes are under utilized but there is a pod disruption budget that is blocking the pods from being moved so nodes can’t scale down

General k8s

1. The pod can’t be created because the image can’t be pulled (ImagePullBackOff). This is because the cluster is private and the image is in a public repo (only accessible over the internet). Configure a NAT gateway or use gcr.io to store images (Note that this image is currently not being mirrored by Google, this may change in the future. If the pod was running for you, this is why)

2. We can see the pods are scheduled but not running. By viewing the pod events, we can see that the readiness probe is failing with 404, likely because it is misconfigured

3. The pod is getting error: CrashLoopBackOff which means the container keeps crashing so the pod is no longer trying to run it. First step in debugging would be to run the container in a non GKE environment. 
In this case, no task is running in the container so it completes and restarts immediately, you can see this due to the exit code 0 in the pod status section.

4. My “fab-four” pods have anti-affinity, they will not schedule on a node where another fab-four pod already exists. My cluster only has 3 nodes and no autoscaling. The pods can only be scheduled if I get more nodes.

5. The LoadBalancer service is configured with loadBalancerSourceRanges which only allows specified IP ranges. 

6. The pod is exposing the port 80 but my Load Balancer service is using target port 8080. Traffic is going to the wrong port

7. Ingress needs to point to a backend service (nodePort or LoadBalancer service). In this case, the ingress is created in the default namespace, so it is looking for a service named “nginx” in the default namespace. The service is created in the “nginx” namespace.

8. The ingress has unhealthy backends. 502 errors are coming from the Load Balancer. View the Load Balancer logs to get more details about the specific 502 error

9. There is nothing wrong with any of the config. The ingress should work, there are no errors anywhere. The ‘HTTP load balancing’ addon is disabled so the ingress can’t be provisioned.

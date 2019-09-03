## GKE specific

1. Why did the `standard-cluster-1` cluster fail to be created? How can I prevent this from happening with a new cluster?

2. My `hippo` cluster worked fine with 2 nodes, I need to add one but it won’t work, why?

3. kubectl commands from my workstation to the `hippo` cluster are timing out, this works fine from the `bastion` VM I have setup. Why do the requests from workstations timeout?  

4. I want to manage my `mongoose` cluster from my `bastion` VM using the cluster's internal endpoint instead of the external one, why is this failing?.

5. I have enabled autoscaling in my lion cluster, but my `bigjob` deployment still has unschedulable pods, why isn’t autoscaling working?

6. In my “narwhal” cluster, I can’t reach my internal database from my `api` which is located in another subnet on my shared VPon prem in the 192.168.128.0/17 block. I don't have this problem with my `fab-four` pods or my bastion host.

7. Autoscaling is enabled on the `mongoose` cluster. There are multiple nodes with under 50% resource usage, why won’t it scale down?

## General Kubernetes

1. In the `hippo` cluster, can you explain what the error message for `promsd` means? What is the cause? How can I fix this?

2. Why isn’t my `working` deployment in the lion cluster working? The pod says it’s running!

3. My `job` workload in the lion cluster doesn’t seem to be working. Can you tell me what is wrong or what the next steps in debugging it would be?

4. The `fab-four` deployment in the narwhal cluster should have 4 pods, why are only 3 running?

5. My `mounter` pod is stuck in pending, why?

6. There is a service called `webserver`, I have tested the pod internally and I am confident that the pod is serving traffic properly. Why doesn’t the Load Balancer seem to work?

7. There is a service called `nginx` in the hippo cluster, I have tested the pod internally and I am confident that the pod is serving traffic properly. Why doesn’t the Load Balancer seem to work?

8. I created an ingress for my `nginx` workload since the service load balancer is not working. Why isn’t my ingress working?

9. My `working` ingress is returning 502 errors. Why is this happening?  How can I debug this?

10. My `echoheader` workload has been exposed with an ingress, yet there is still no external IP, what am I doing wrong?

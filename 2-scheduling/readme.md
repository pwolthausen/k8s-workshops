# Pod scheduling

1. Resource requests
2. [Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
3. [Node selector](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)
4. [Pod affinity/anti-affinity](https://docs.openshift.com/container-platform/3.6/admin_guide/scheduling/pod_affinity.html)


## Resource requests

K8s leverages resource requests for many different aspects, including scheduling, auto-scaling and pod preemption. It is best practice to have these configured for all your pods([see best practices video](https://www.youtube.com/watch?v=xjpHggHKm78)). Deciding on which value to set for the request depends entirely on the container being deployed. See [this](https://opensource.com/article/18/12/optimizing-kubernetes-resource-allocation-production) blog about determineing resource requests and limits for your containers.

1. Given deployment, determine appropriate resource requests

As k8s cluster admin, it is good practice to [enforce resource requests per namespace](https://kubernetes.io/docs/concepts/policy/limit-range/) in case users forget to set them.

2. Set resource request default values at the namespace level

3. Set resource request limitations per namespace

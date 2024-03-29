# Services in k8s

[Services](https://kubernetes.io/docs/concepts/services-networking/service) are used to expose k8s workloads by providing a single access point for the ever changing set of pods. This is handled by creating rules in the iptables of each of the nodes in the cluster. The different service types handle this differently.

## 1. Service types

There are 4 [types of services in kubernetes](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types):  

- ClusterIP
- NodePort
- LoadBalancer
- ExternalName

### ClusterIP

Aside form ExternalName, each of the other 3 build on top of each other. At the base is the clusterIP.
A virtual IP is selected from the cluster's range of service IPs, this IP remains static as long as the service exists and will persist through node changes and version upgrades.
A route is created within the cluster that states any packet with the destination IP that matches the service IP will be treated by the service and forwarded to one of the serving pods.
How this is accomplished will depend on the [service proxy mode](https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies)
An important limitation with CLusterIP is that the virtual IP can only be reached from within the cluster.

### NodePort

NodePort is used to expose your workloads externally, outside of the cluster.  
NodePort keeps the clusterIP model and builds on top of it. The virtual IP and iptable rules are both kept. On top of that, a port is selected from a predefined range (default: 30000-32767) which is assigned to each node. The service will listen on this port on each node and forward traffic to a serving pod based on the proxy mode.   
NOTE: NodePort service is generally used when an external Load Balancer is leveraged such as with an Ingress on GKE.

### LoadBalancer

LoadBalancer service type exposes the the workloads outside the cluster using a single IP. This service will leverage a Cloud Provider's Load Balancer. How traffic is routed to the nodes and pods will vary based on the providers configuration.
The LoadBalancer service still includes the ClusterIP and a nodePort, even if neither are explicitely used.  

### ExternalName

ExternalName works essentially as a CNAME record. No proxying is done.



For some hands on with exposing services, [here is a good repo](https://github.com/DanyLan/GKE-EXPOSE-SERVICES) that goes through each serive type and demonstrates how to access them.  

And [here is a great blog](https://matthewpalmer.net/kubernetes-app-developer/articles/kubernetes-ports-targetport-nodeport-service.html) that explains what `port`, `nodePort`, and `targetPort` are, what they do, and the differences.

## 2. How services expose pods

How the service routes traffic to pods will vary depending on the service type, proxy mode and Cloud Provider.  
What remains constant is how services select which pods to expose. The two features that services rely on are `labelSelectors` and a pods `readinessProbe`.

### Label selector

The service `spec.selector` will contain a mapping of labels. Any pod within the same namespace that matches the labels will receive traffic.
To demonstrate this, we'll deploy a couple of deployments using some similar and some different labels, do so using the `deploy.yaml` included here.

    kubectl apply -f deploy.yaml  

Three deployments are created, 2 in one namespace and a third in another, all of which share a label. (use `kubectl get deploy --all-namespaces -l app=web`)
We'll start with a basic service:

<pre>
apiVersion: v1
kind: Service
metadata:
  name: web-app
spec:
  selector:
    app: web
  ports:
  - port: 8080
    targetport: 80
</pre>

For the purpose of demonstrating how the labels work, we'll apply the `services.yaml`.

    kubectl apply -f services.yaml

This will create 4 services. Let's first look at the service `web-app`. Notice that this service uses the label `app: web` which is also used by all 3 deployments.
The service will create an `endpoint` resource which reflects the service virtual IP and group together the pod IPs of the pods with the same label.  

    kubectl describe ep web-app

The pods grouped into this endpoint are the same as those you find when listing pods by a label:

    kubectl get po -l app=web -o wide
    kubectl get po -l app=web --all-namespaces

After running the first command, you should see pods from 2 different deployments because they each share the same label. When traffic is sent to the service, either of the two workloads will receive traffic.  
Running the second command, you should notice there are more pods than there are listed in the first or in the endpoint. This is because the service does not match labels accross multiple namespaces.  

To demonstrate this, SSH into one of the nodes and run `sudo toolbox bash`.
Note this only works with nodes running COS image. If you are not using GKE or a COS image, instead use `docker run -it busybox --image busybox -- /bin/sh`  
From this toolbox environment, try to curl the service (you can either use the clusterIP or leverage the cluster DNS `web-app.default`)  
When running this curl multiple times, you should see different results: some from the nginx pods, and others from the apache pods.

You can view how the different services target different pods by running the same tests against the other 3 services.

### Services and readinessProbes

Readiness probes are not actually part of a service. Readiness probes are configured in the pod spec of each individual workload. The [Readiness Probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes) is used to determine when a pod is ready to serve traffic. This is different from a [liveness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command) which acts more like a health check. Although these two probes serve different purposes, they are eached configured similarly.

A service will only include pods that are seen as ready as one of its endpoints. As pods are added or removed from the cluster, the service controller will add or remove them from the service. It is important to ensure a valid and accurate readiness Probe is configured on your pod to ensure that pods are not added to the service and start receiving traffic before they are ready to actually serve traffic. This is especially important for workloads that scale up and down regularly.


## 3. Services in the wild

<I'm not sure what I wanted to cover in this section???>

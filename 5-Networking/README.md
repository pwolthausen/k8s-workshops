# Networking

Most of the networking in kubernetes is handled by the chosen network provider and does not require much user input.
There are a number of [network options to choose from](https://kubernetes.io/docs/concepts/cluster-administration/networking/), though this workshop will not be going into the different types. Take the time to explore the different options and choose which one is best for your cluster. Note that some managed clusters only allow limited networking options.

## Ingress

Ingress resources are likely the most commonly used networking resource. Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource. (See [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) from the k8s documentation)

Something of note with Ingress definitions is that the metadata.annotations field is used heavily. Each Ingress provider allows multiple features that are defined in the annotations section (such as disabling HTTP, configuring tls, configuring redirects, setting the public IP, etc).  

The bulk of the resource definition is rules which match paths with the desired services. Each rule contains the following information:

- host: This field is optional. Host is the fully qualified domain name of a network host, incoming requests are matched against the host before the ingress rule evaluates the request. If no host is specified, the rule will apply to all inbound HTTP traffic.

- Path: a list of paths can be provided which can include wildcards. The rule will apply to any incoming traffic that matches the path (example: /login). Each path can define a different backend. Unmatched traffic will be sent to the [DefaultBackend](https://kubernetes.io/docs/concepts/services-networking/ingress/#default-backend), ensure you are aware of the defaultbackend behavior and configure as needed.

- Backend: Each path must have a backend. The backend is a combination of service.name and service.port. Requests that match the host and path will be forwarded to the associated backend.

There are a number of ingress controllers and each are implemented differently and thus how they work differs slightly, however, the resource definition remains the same for each of the providers.

## Network Policy

## Cluster DNS

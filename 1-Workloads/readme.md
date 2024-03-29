# Workloads

1. [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
2. [ReplicaSets](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
3. Using a Deployment
4. Writing a Deployment
5. Configure the container using Environment Variables
6. Add volumes
7. [Explore StatefulSet](https://cloud.google.com/kubernetes-engine/docs/concepts/statefulset)
8. Jobs Vs Deployments

## Intro

Kubernetes is a container orchestration tool, as such, you will be using it to deploy and manage workloads which run in containers. Knowing how to deploy and configure your workloads is the first step in adopting kubernetes.

### Pods

A pod is the smallest deployable  unit of computing that you can create and manage in kubernetes. It is important to remember this, a k8s cluster does not manage containers, it manages pods.

Generally speaking, a single pod will contain a single container along with everything that container needs to run. A single pod can contain multiple containers if needed, though. The pod will also contain a NIC and any volumes the containers will require.  

<p align="center">
  <img src="pod-arch.png" />
</p>

### ReplicaSets

A replicaSet is a resource used to tell the cluster how many replicas of a pod are needed. The controller will regularly check how many pods are currently running (current state) against how many have been requested (desired state) and schedule or remove pods to ensure you end up with the correct number of pods running.

<p align="center">
  <img src="replicaset.png" />
</p>

A replicaSet can be scaled up or down with an easy command:

> kubectl scale rs <replicaset_name> --replicas x

## Deployments

### Why use Deployments?

Deployments are generally used in lieu of using un-managed pods or ReplicaSets. The Deployment will control ReplicaSets, which in turn control pods. Aside from the benefits provided by a ReplicaSet built in, Deployments also provide upgrade strategies when changes are made to the workload (such as rolling out new versions).

To demonstrate some features of a Deployment, use the `demo.yaml` file to create a few resources.

>    kubectl apply -f demo.yaml

The Deployment in question is the `demo` deployment (`kubectl get deploy` to list created deployments).
Looking at the deployment yaml, notice the `spec.strategy` field. This defines how the deployment will roll out new pods when a change is made to the config. There are two fields to highlight here:

- `spec.strategy.rollingUpdate.maxSuge`: Sets the number of additional pods (above the number defined in the `replicas` field) that can be created during an update.

- `spec.strategy.rollingupdate.maxUnavailable`: Sets the maximum number of pods that can be unavailable during the update.

In the current example, there are 4 replicas with a max surge of 1 and max unavailable of 1. This means that during an update, the deployment can go up to 5 total pods and can go down to 3 total available pods (ready).
As the strategy mentions, this is a rolling update. This means that new pods are added based on the defined values. New pods must become ready before old pods are removed.  
In the current example, the deployment will terminate 1 of the current pods (maxUnavailable 1) and create 2 new pods (1 to replace the old terminated pod, and 1 surge pod). As soon as soon as one of the new pods is ready, the next old pod is removed.

We can trigger an update on the `demo` deployment and watch the the rolling update behavior.

>    kubectl edit deploy demo

Change the label `version: "1.0"` to `version: "1.1"` and save changes.  
Now watch the deployment roll out

>    watch kubectl get po -l app=demo

**NOTE:** The current example uses set values for maxSurge and maxUnavailable. These values can also be set as a %, this will be a % of the total replicas. Using percentages may be more useful when using very large number of replicas or if the number of replicas will change frequently (such as when using HPA).


### Creating a Deployment

Using the basic deployment template (deployment.yaml), fill in the blank fields to deploy a basic database. To keep things simple, let's use the image for mariadb from Docker Hub: ["mariadb:latest"](https://hub.docker.com/_/mariadb).  
Once the yaml is ready, save your changes and create the deployment using:

>    kubectl apply -f deployment.yaml

Changes in future steps can be applied easily in one of 2 ways:
1. Edit the deployment.yaml file locally. Once changes are complete, run the above command again to update the k8s resource
2. Edit the deployment resource directly through k8s using `kubectl edit deploy [deployment_name]`. Note that this uses vi to edit the resource config stored in the clusters etcd and not all fields can be changed this way.  


## Setting Variables for the container

The MySQL database requires a root password which we will set through an environment variable. We can also set other variables such as a non root user, the non root user password and set a starting database.
Looking at the description on Docker Hub, we can see a number of Environment Variables, we will set these 4:

- MYSQL_ROOT_PASSWORD
- MYSQL_DATABASE
- MYSQL_USER
- MYSQL_PASSWORD

To do this in the deployment.yaml, we need to [add the environment variables](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/#using-environment-variables-inside-of-your-config) to an array as part of the container object
The deployment currently has a variable defined that allows access without a password, let's go ahead and replace that.

<pre>
containers:
- env:
  - name:
    value:
</pre>

Once the Environment variables have been changed, you can try logging into the DB by using port-forwarding: `kubectl port-forward deploy/[deployment_name] 8090:80`
Now use `curl localhost:8090` or open your browser on the same machine and go to `http://localhost:8090`; you should be able to login with the credentials you set in the variables.

## Adding volumes

Volumes are sources of data that the pod consumes. This can be raw data or storage volumes attached to the pod which the container can mount. The k8s ecosystem has many different types of storage providers available, this section will not be covering these providers, it is strongly recommended that you take the time to explore the different storage providers available and choose the one that is right for your workloads and your cluster.

### 1. ConfigMap

We might want to create a standardised deployment that we can re-use for different workloads, but allow for different variables in each one. Instead of setting the variables in the deployment as we did above, we will [create a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) that will contain the MYSQL_DATABASE and MYSQL_USER data.
To keep things simple, let's create the ConfigMap using [literal values](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-configmaps-from-literal-values). Run the following command:

>    kubectl create configmap db-variables --from-literal=database=[database_name] --from-literal=db-user=[username]

Take a look at the resource you just created using `kubectl describe cm db-variables`

To use the two values we just set in the ConfigMap, we will modify the two Environment Variables and replace the clear text we wrote with a reference to the configmap data
We will replace the `value` field with a `valueFrom` field. It should look something like this:

<pre>
...
valueFrom:  
  configMapKeyRef:  
    name: db-variables  
    key: database
</pre>

You can learn more about this field using `kubectl explain` or using the [API reference](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#environment-variables)

### 2. Secrets

Our container currently has the 2 passwords writen in plain text in the config file. This is obviously not a good practice as we'd rather keep these passwords secure. Using a configMap here wouldn't help much as the data will be stored in clear readable text. Instead, we'll use a secret.  
There are a number of ways to [generate the secret](https://kubernetes.io/docs/concepts/configuration/secret/#creating-your-own-secrets), for now, we'll create it from the command line; follow the steps to manually create a secret using the kubectl `--from-file` flag from the [kubernetes.io page](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/).

Once the secret has been created, you can view the secret using `kubectl describe secret [secret_name]`. Note that instead of having the values in clear text, the secret just makes a reference to the source file. This will also be the case if you create the secret from a literal value, you should only see the number of bytes of the value rather than a clear text value.

Now, update the deployment env fields to use the secrets. This will be very similar to how we referenced configMaps. Use `kubectl explain` or view the [k8s API reference docs](ttps://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#environment-variables) to find the correct values to change.

[Here is an example of using secrets in the real world](https://cloud.google.com/kubernetes-engine/docs/tutorials/authenticating-to-cloud-platform).

### 3. Persistent Volumes

We used configMap and secrets to replace variables in the container. It is also possible to have entire files created from either a secret or a configMap. The important part to note is that whatever data we import from the configMap or the secret will be readOnly.  

Your container, however, may required an entire directory of preloaded data or it may need writable, persistent disk space. To address this, we can mount disks to the pod using [Persistent Volumes(PV) and persistent volume claims(PVC)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

**Note** Some providers will use StorageClass to allow PVs to be provisioned dynamically when you create a PVC. We will get more in depth into storage in a later workshop.

Start by creating the Persistent Volume using the `kubectl apply` command.  
- If you are using a cluster that has a storage class (such as a GKE cluster), use the provided `pvc_with_class.yaml` file.
- If you are using a cluster without a storage class configured, use the `classless_pvc.yaml` file.  

Next, edit the deployment to indicate the volume to use by adding the `spec.template.spec.volumes` field.  
  
<pre>
...
spec:
  volumes:
  - name: mysql-volume
    persistentVolumeClaim:
      claimName: mysql-pvc
</pre>
  
Finally, mount the volume by adding the `spec.template.spec.containers.volumeMounts` field.  
  
<pre>
...
spec:
  containers:
  - name: ...
    volumeMounts:
    - mountPath: "/var/lib/mysql"
      name: mysql-volume
</pre> 
  
Set the `mountPath` to `/var/lib/mysql` so we can use it for the database.  

Once your pod is running, you can verify that the PVC is properly being used by describing it:

>    kubectl describe pvc $(kubectl get pvc --no-headers=true -o custom-columns=:metadata.name)

If you are using a storage provider, you can experience the behavior of a PVC by draining the node (`kubectl drain node <node_name>`) where the MySQL pod is scheduled. You'll notice the PVC will change nodes along with the pod and the data will be kept.

## StatefulSets

Statefulsets work very similarly to the deployment we just created with a few differences. We'll explore the differences here.
Start by creating the basic statefulset provided (stateful.yaml) and take the time to note the naming convention and how it differs from the pod created by the deployment.

Next, we'll highlight the fields specific to StatefulSets that provide new functionality:

1. `spec.podManagementPolicy`: this defines how pods are created and managed within the set, try different values and watch how the controller manages the pods as they are deleted and/or recreated.

2. `spec.serviceName`: this field requires that the service already exist and provides hostnames for the pods which the cluster DNS can resolve.

3. `spec.volumeClaimTemplates`: Creates a template for PVCs, each new replica will have it's own dynamically provisioned PVC created and attached. the PVCs follow a similar naming convention to the pods. This makes scaling up and down easier since we no longer have the issue of a single PVC assigned in the pod template getting re-used (a problem we see in deployments). Note that this field replaces the `spec.template.spec.volumes` field found in deployments and requires a storage class to be configured in the cluster.

Try adding these fields to the statefulset and watch how they are implemented.
[Here is an example](https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/) use case of a StatefulSet in action to create a MySQL master and replicas.


## Jobs Vs Deployments

A deployment should create long lasting containers that are built to serve requests. Deployments do not work well with short lived containers such as a script that only needs to run once.
To demonstrate this limiation with Deployments, creat ethe "job" deployment using the job.yaml
After a minute or so we should see that all the pods are in creashLoopBackOff. Describing the pod will provide more details. Notice that the last exit code is 0.

Since the nature of this pod is short lived, let's change this over to a job instead. In this case, editing the resource would not work, so let's delete the `job` deployment first.
Open `job.yaml` and make the following changes to convert it to a job:

1. Change `apiVersion` from v1 to batch/v1
2. Change `kind` to Job
3. Remove the `spec.replicas` field
4. Remove the `spec.selector` field. This field will be generated automatically.
5. Add the `spec.completions` and `spec.parallelism` fields. These are integers and determine how many times the job should run and how many replicas can run at any time.
6. OPTIONALY add the `spec.ttlSecondsAfterFinished`. Adding this field will keep a pod around after it has completed it's task, useful for debugging or reviewing container logs

Once you've made these changes, apply the new config and watch as the jobs run.
If you need these jobs to run on a schedule, you can use the kind [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

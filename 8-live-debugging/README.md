
# Setting up the Troubleshooting environment

This workshop assumes you have the Google Cloud SDK installed.

### 1. Create a new project

Part of the deployment manaifest will delete your default VPC. Other steps will also create resources that can't be easily deleted using deployment manager, thus, for easy clean up, I highly recommend running this environment in a new project.
If you do not want to create a new project for this workshop, remove the first resource (named `default-vpc`) before deploying.

### 2. Enable the APIs

Make sure the following APIs are enabled in the project. For new projects, you will need to enable them. If you are using an existing project, these may already be active.  
    - compute.googleapis.com  
    - container.googleapis.com  
    - deploymentmanager.googleapis.com  
    - logging.googleapis.com  

Use the following command to ensure the APIs are enabled

    gcloud services enable compute.googleapis.com container.googleapis.com deploymentmanager.googleapis.com logging.googleapis.com

### 3. Create the resources

#### The Clusters

Make the workloads.sh file executable. This is a simple bash script that creates a deployment using deployment manager then connects to each cluster and applies the correlating yaml  

    chmod 760 setup.sh

Run the executable. You may see an error for the `unicorn` cluster, disregard this error.

    ./setup.sh

The above script will create the deployment which will perform the following:

- Remove the default VPC
- Create 2 new VPCs peered together
- Create 5 GKE clusters with 2-6 nodes each (make sure to have sufficient quota for this)
- Create a Bastion host (the VM uses osLogin, so you need to make sure you have sufficient permissions to connect). Note, connecting to the bastion is not required.


### 4. Scenarios

Open the [Questions.md](https://github.com/Aahzymandius/k8s-workshops/blob/aahz-changes/8-live-debugging/Questions.md) file and go through the 17 questions. These questions will cover both GKE specific issues as well as broader k8s common issues.  

As a reference, the Answers.md file includes the solutions to most of these scenarios


### 5. Cleaning up

If you made a new project, you can simply delete the project.  
If you wish to keep the project, due to resources such as new gcp types and the peerings, DM will not be able to automatically remove all created resources. You will have to delete the deployment then manually remove any unwanted resources.

    gcloud deployment-manager deployments delete gke-test --delete-policy abandon

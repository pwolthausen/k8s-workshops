#! /bin/bash

for cluster in $(gcloud container clusters list --format='table(name)'); 
do
  gcloud container clusters $cluster get-credentials
  kubectl apply -f $cluster.yaml
done

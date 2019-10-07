#! /bin/bash

echo Enter project ID

read project

for cluster in $(gcloud container clusters list --format='table[no-heading](name)' --project $project); 
do
  gcloud container clusters get-credentials $cluster --project $project --zone us-central1-f
  kubectl apply -f $cluster.yaml
done

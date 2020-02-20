#!/bin/bash
kubectl delete -f app/ -R
kubectl delete -f kubernetes/ -R
sleep 600
kubectl get ns
cd terraform
terraform destroy -auto-approve
#!/bin/bash
mkdir ~/.kube/
cd terraform/
terraform init
terraform apply -auto-approve
sleep 10
terraform output kubeconfig>~/.kube/config
terraform output config_map_aws_auth > configmap.yml
kubectl apply -f configmap.yml
kubectl get nodes -o wide
cd ..
cd kubernetes
kubectl apply -f cert-manager/ -R --validate=false
kubectl apply -f metrics-server/ -R
kubectl apply -f nginx/ -R
kubectl get pods -n cert-manager
sleep 300
kubectl apply -f cert-manager-issuers/ -R
cd ..
kubectl apply -f app/load-balancer/ -R
sleep 15
kubectl get svc -n default
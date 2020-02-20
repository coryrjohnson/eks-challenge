#!/bin/bash
kubectl delete -f app/load-balancer/ -R
kubectl apply -f app/ingress/ -R
sleep 60
kubectl describe orders.acme.cert-manager.io -n default
kubectl get svc -n ingress-nginx

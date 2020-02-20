# EKS Challenge 

What You’ll Need

Before you get started, you’ll need a few tools installed. Terraform is a tool to create infrastructure. Kubectl is the CLI tool for Kubernetes. Aws-iam-authenticator is used to authenticate to your EKS cluster alongside kubectl. You’ll need to install them all if not already installed:

terraform – https://www.terraform.io
kubectl - https://kubernetes.io/docs/tasks/tools/install-kubectl/
aws-iam-authenticator - https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html

You will need a set of AWS API credential configured in ~/.aws/credentials with access to create VPCs, Subnets, Route Tables, Internet Gateways, IAM Roles, IAM Policies, and EKS cluster resources.

Get started:

git clone https://github.com/coryrjohnson/eks-challenge.git

Terraform tracks the state of your infrastructure in a state file. In this challenge we will be storing the state file locally, in a production enviornment you would want to store your state in a centralized backend such as S3.

Open Terminal

CD to eks-challenge directory

cd terraform

terraform init
This will initialize Terraform state to track your work.

terraform plan
This will show a details outline of changes Terraform will perform.

terraform apply
This will apply the changes previously shown in plan into production, this will utilize the AWS credentials configured in earlier steps to access the AWS API.

Type yes to approve if apply matches expected plan

This process should take ~15 minutes. 

Run:
mkdir ~/.kube/ (if this directory does not already exist)

terraform output kubeconfig>~/.kube/config
This will generate the credential file needed to access the Kubernetes cluster. (Rename or move existing kube config file if you already have one in place, this will override existing config.)

terraform output config_map_aws_auth > configmap.yml
kubectl apply -f configmap.yml
This will allow our EKS cluster access to our managed node groups.

kubectl get nodes -o wide
Checks that your nodes are available and in a ready status.

CD to eks-challenge directory

cd kubernetes

kubectl apply -f cert-manager/ -R --validate=false

kubectl apply -f metrics-server/ -R

kubectl apply -f nginx/ -R

In order to apply the next resources you will need to validate all existing cert-manager pods are running.

kubectl get pods -n cert-manager

Once all three pods for cert-manager are in ready status 1/1 available run the following:

Open and change issuer YAML files with your email.

kubectl apply -f cert-manager-issuers/ -R

CD to eks-challenge directory

kubectl apply -f app/load-balancer/ -R

kubectl get svc -n default
Retrieve the load balancer external hostname

kubectl get svc -n default
NAME                      TYPE           CLUSTER-IP      EXTERNAL-IP                                                             
hello-kubernetes-custom   LoadBalancer   172.20.72.108   aa4f7d65a537111ea824c1207981d2f7-490501244.us-east-1.elb.amazonaws.com 

Navigate to External-IP hostname in browser to verify traffic being delivered to hello-world pod. This method only provisions a Load Balancer to deliver traffic over HTTP, not HTTPS. LoadBlancer may take up to 5 minutes to fully provision and DNS to propogate.

See Optional steps below to utilize the nginx ingress controller and cert-manager for HTTPS.

OPTIONAL

CD to eks-challenge directory

kubectl delete -f kubernetes/app/load-balancer/ -R

Open optional/hello-world-ingress.yaml and edit following lines to utilize your own domain name.

  - hosts:
    - hello-world.mydomain.com - BOLD

  rules:
  - host: hello-world.mydomain.com - BOLD

Save file.

Apply Deployment
kubectl apply -f app/ingress/ -R

This is the same deployment but utilizes a ClusterIP service and the nginx ingress controller to receive traffic.

kubectl describe orders.acme.cert-manager.io -n default

A challenge response to validate ownership of the domain will be presented with an option for DNS. Copy the token shown in the order resource. It will be similiar to this value: TsXCLQPtUn_AjgdXkHSanUlr8ES-WtTXZRzDqi3utXI

kubectl get svc -n ingress-nginx
Copy the external-IP shown for the nginx service. 

Go to your domain registrar for the domain you put in the hosts in rules above.

Create two records:

CNAME hello-world.mydomain.com to the external-ip of the nginx service.

TXT for _acme-challenge.hello-world.mydomain.com with a value of the token pulled from the order above.

Once validation completes you should be able to navigate to your domain (i.e. hello-world.mydomain.com) with a valid SSL certificate.



TEARDOWN

Remove any DNS entries you created in the optional steps above with your DNS registrar.

CD to eks-challenge directory

kubectl delete -f app/ -R
kubectl delete -f kubernetes/ -R

kubectl get ns

Validate only remaining namespaces are: (May take several minutes after the delete commands.)

NAME              STATUS        AGE
default           Active        74m
kube-node-lease   Active        74m
kube-public       Active        74m
kube-system       Active        74m

cd terraform

terraform destroy

Type yes to approve if destroy matches expected resources to be removed.

This process will take ~15 minutes. Once complete all resources should be removed from AWS.



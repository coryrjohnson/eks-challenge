# EKS Challenge

 ## What You’ll Need


Before you get started, you’ll need a few tools installed. Terraform is a tool to create infrastructure. Kubectl is the CLI tool for Kubernetes. Aws-iam-authenticator is used to authenticate to your EKS cluster alongside kubectl. You’ll need to install them all if not already installed:

**terraform** – https://www.terraform.io

**kubectl** - https://kubernetes.io/docs/tasks/tools/install-kubectl/

**aws-iam-authenticator** - https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html

  
You will need a set of AWS API credential configured in *~/.aws/credentials* with access to create VPCs, Subnets, Route Tables, Internet Gateways, IAM Roles, IAM Policies, and EKS cluster resources.

  

## Get started:

  

    git clone https://github.com/coryrjohnson/eks-challenge.git

Terraform tracks the state of your infrastructure in a state file. In this challenge we will be storing the state file locally, in a production enviornment you would want to store your state in a centralized backend such as S3.

Open Terminal.


Change directories to eks-challenge directory.

cd terraform

Opens the Terraform directory.  

    terraform init

Terraform init will initialize the state to track your work.

    terraform plan

Terraform plan will show a details outline of changes Terraform will perform.

    terraform apply

Terraform apply will apply the changes previously shown in plan into production, this will utilize the AWS credentials configured in earlier steps to access the AWS API.

    yes

Type yes to approve if apply matches expected plan.

This process should take **~15 minutes**.

The following resources are being created:

-   VPC
-   IAM roles
-   Security groups
-   An internet gateway
-   Subnets
-   Autoscaling group(s)
-   Route table
-   EKS cluster
-   Your kubectl configuration

Once the terraform apply completes run the following:

`mkdir ~/.kube/` 
>If this directory does not already exist

Creates the directory to store your kube config in your home folder.

    terraform output kubeconfig>~/.kube/config
>Rename or move existing kube config file if you already have one in place, this will override existing config.

Generates the credential file needed to access the Kubernetes cluster. 

    terraform output config_map_aws_auth > configmap.yml

Generates configuration needed to map Worker nodes to EKS cluster.

    kubectl apply -f configmap.yml

Applies configuration needed to map Worker nodes to EKS cluster.

    kubectl get nodes -o wide

Checks that your nodes are available and in a ready status.

Change directories to eks-challenge directory.

The following commands apply the resources needed to run your application. This includes the following:

 - Cert-Manager
 - Metrics-Server
 - Nginx Ingress Controller

Cert-Manager manages and created the SSL certificates used by our ingress resources.

Metrics-Server monitors the CPU and Memory usage to help with our HPA(s).

Nginx controls and routes traffic into our cluster and to our backend services.

    cd kubernetes

    kubectl apply -f cert-manager/ -R --validate=false

    kubectl apply -f metrics-server/ -R

    kubectl apply -f nginx/ -R

 
In order to apply the next resources you will need to validate all existing cert-manager pods are running.

    kubectl get pods -n cert-manager


Verify all three pods for cert-manager are in ready status 1/1 available.

Open *eks-challenge\kubernetes\cert-manager-issuers\prod_issuer.yaml* and *eks-challenge\kubernetes\cert-manager-issuers\staging_issuer.yaml* and change the **email** in the spec to match your email address.

    kubectl apply -f cert-manager-issuers/ -R

 Applies the certificate issuer resources used for LetsEncrypt certificates. 
 
Change directories to eks-challenge directory.

    kubectl apply -f app/load-balancer/ -R

Applies the manifests for our hello-world application using a traditional **LoadBalancer** type service.

    kubectl get svc -n default

Retrieves the load balancer external hostname.
 
Output of the external-IP will look something like this:

> aa4f7d65a537111ea824c1207981d2f7-490501244.us-east-1.elb.amazonaws.com

 
Navigate to External-IP hostname in browser to verify traffic being delivered to hello-world pod. This method only provisions a LoadBalancer to deliver traffic over HTTP, not HTTPS. LoadBalancer may take up to 5 minutes to fully provision.

> See Optional steps below to utilize the nginx ingress controller and
> cert-manager for HTTPS.

  

## OPTIONAL

Change directories to eks-challenge directory.

    kubectl delete -f kubernetes/app/load-balancer/ -R

Open *eks-challenge/app/ingress/hello-world-ingress.yaml* and edit following lines to utilize your own domain name.

    - hosts:
	  - hello-world.mydomain.com

  AND

    rules:
    - host: hello-world.mydomain.com

Save file.

Apply Deployment

    kubectl apply -f app/ingress/ -R

This is the same deployment but utilizes a ClusterIP service and the nginx ingress controller to receive traffic.

    kubectl describe orders.acme.cert-manager.io -n default

A challenge response to validate ownership of the domain will be presented with an option for DNS. Copy the token shown in the order resource. It will be similiar to this value: 

> TsXCLQPtUn_AjgdXkHSanUlr8ES-WtTXZRzDqi3utXI

    kubectl get svc -n ingress-nginx

Copy the external-IP shown for the nginx service.


Go to your domain registrar for the domain you put in the hosts in rules above.

Create two DNS records:

**CNAME** hello-world.mydomain.com to the external-ip of the nginx service.

**TXT** for _acme-challenge.hello-world.mydomain.com with a value of the token pulled from the order above.

Once validation completes you should be able to navigate to your domain (i.e. hello-world.mydomain.com) with a valid SSL certificate.

  

## TEARDOWN

  

Remove any DNS entries you created in the optional steps above with your DNS registrar.

Change directories to eks-challenge directory.

    kubectl delete -f app/ -R

Deletes any application resources.

    kubectl delete -f kubernetes/ -R

Deletes any Kubernetes resources we deployed, most importantly the LoadBalancer created by Nginx.

    kubectl get ns

Validate only remaining namespaces are:

NAME

- default
- kube-node-lease
- kube-public
- kube-system

> May take several minutes after the delete commands.

    cd terraform

Open terraform directory.

    terraform destroy

Starts plan to destroy AWS resources deployed by Terraform.

    yes

Type yes to approve if destroy matches expected resources to be removed.

This process will take ~15 minutes. Once complete all resources should be removed from AWS.

**Complete.**
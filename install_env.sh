#/bin/bash
#Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/v1.31.2/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm -f ./minikube-linux-amd64

#Install Kubectl
curl -LO "https://dl.k8s.io/release/v1.21.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f ./kubectl

#Install Docker Runtime
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
newgrp docker

#Install Git
sudo yum install git -y

#Install "conntrack"
sudo yum install conntrack -y

#Istart Minicube
minikube start --memory 8192 --cpus 2
sudo chown -R $USER $HOME/.minikube; chmod -R u+wrx $HOME/.minikube

#Download Boutique
git clone https://github.com/Mark-McCracken/online-boutique

#Download "Istrio"
curl -L https://istio.io/downloadIstio | sh -
export PATH=$PWD/bin:$PATH


#Install Istio
export PATH=/home/ec2-user/istio-1.18.2/bin:$PATH

cd /home/ec2-user/istio-1.18.2

#Install Istio with the demo profile
istioctl install --set profile=demo --set hub=gcr.io/istio-release -y

sleep 10

#Install Boutique Demo Application

  cd /home/ec2-user/online-boutique/


#Create Kubernetes namespace to house our Boutique application in
kubectl create ns boutique

#Create secret for accessing your LightStep environment
#kubectl -n boutique create secret generic lightstep-credentials --from-literal=accessToken="<LightStep Access Token>"

#Enable Istio Injection for boutique namespace
kubectl label namespace boutique istio-injection=enabled

#Deploy our boutique application
kubectl -n boutique apply -f ./release/kubernetes-manifests.yaml

kubectl label pods --all Application=${1} -n boutique

#Create Tunnel to allow app to be available externally
nohup minikube tunnel &> /dev/null &

#Get Port Information
port=`kubectl -n boutique get svc/frontend-external | grep frontend | cut -d ":" -f2 | cut -d "/" -f1`
#
# Record Public and Private Application Access

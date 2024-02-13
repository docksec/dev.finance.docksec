#!/bin/bash


curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb


# Atualizar os repositórios
echo "Atualizando os repositórios..."
sudo apt-get update

# Instalar os componentes do Kubernetes
minikube start

sudo snap install kubectl --classic

kubectl get po -A

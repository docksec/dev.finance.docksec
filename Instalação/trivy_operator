#!/bin/bash

# Baixar o script de instalação do Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

# Dar permissão de execução ao script
chmod +x get_helm.sh

# Executar o script para instalar o Helm
./get_helm.sh

# Adiciona o repositório Helm do Trivy Operator
helm repo add aquasecurity https://helm.aquasec.com

# Atualiza os repositórios Helm
helm repo update

# Instala o Trivy Operator usando o Helm
helm install trivy-operator aquasecurity/trivy-operator

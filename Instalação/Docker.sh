#!/bin/bash

# Passo 1: Atualizar a lista de pacotes disponíveis
sudo apt-get update

# Passo 2: Instalar as ferramentas necessárias
sudo apt-get install -y ca-certificates curl gnupg

# Passo 3: Criar um diretório para armazenar a chave GPG
sudo mkdir -p /etc/apt/keyrings

# Passo 4: Baixar a chave GPG oficial do Docker e salvar no diretório '/etc/apt/keyrings/docker.gpg'
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Passo 5: Definir as permissões corretas para a chave GPG
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Passo 6: Adicionar o repositório do Docker às fontes do APT
ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

# Passo 7: Atualizar a lista de pacotes para incluir o repositório do Docker
sudo apt-get update

# Passo 8: Instalação do Docker e Docker Compose
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose

# Passo 9: Adicionar o usuário ao grupo Docker
sudo usermod -aG docker $(whoami)

# Passo 10: Verificar se o Docker foi instalado corretamente
docker --version

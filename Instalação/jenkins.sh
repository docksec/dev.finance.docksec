#!/bin/bash
# Atualiza a lista de pacotes disponíveis e suas versões, sem solicitar confirmação
sudo apt update -y

# Instala o OpenJDK 17, uma implementação de código aberto do Java Development Kit (JDK) 17
sudo apt install openjdk-17-jdk

# Verifica a versão do Java instalada
java -version

# Obtém a chave de assinatura do repositório Jenkins e a salva em um arquivo
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
                  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Adiciona o repositório Jenkins ao sistema, usando a chave de assinatura obtida anteriormente
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                              /etc/apt/sources.list.d/jenkins.list > /dev/null

# Atualiza a lista de pacotes após adicionar o repositório Jenkins
sudo apt-get update -y

# Instala o Jenkins, um servidor de automação de código aberto
sudo apt-get install jenkins -y

# Inicia o serviço do Jenkins
sudo systemctl start jenkins

# Verifica o status do serviço do Jenkins para garantir que esteja em execução corretamente
sudo systemctl status jenkins

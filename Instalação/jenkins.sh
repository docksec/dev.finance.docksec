#!/bin/bash
sudo apt update -y
#Instalação Java Temurin 
wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jdk_x64_linux_hotspot_21.0.2_13.tar.gz
tar -xvf OpenJDK21U-jdk_x64_linux_hotspot_21.0.2_13.tar.gz
sudo mkdir -p /usr/lib/jvm
sudo mv jdk-21.0.2 /usr/lib/jvm/
export JAVA_HOME=/usr/lib/jvm/jdk-21.0.2
export PATH=$JAVA_HOME/bin:$PATH
source ~/.bashrc
java -version
#Instalação do Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
                  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                              /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y
sudo systemctl start jenkins
sudo systemctl status jenkins

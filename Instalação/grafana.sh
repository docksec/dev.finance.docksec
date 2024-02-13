#!/bin/bash

# Atualizar a lista de pacotes disponíveis
sudo apt update

# Instalar o Grafana
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt update
sudo apt install -y grafana

# Iniciar e habilitar o serviço do Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Exibir informações de status do Grafana
echo "Grafana status:"
sudo systemctl status grafana-server

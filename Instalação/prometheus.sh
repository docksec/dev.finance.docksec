#!/bin/bash

# Atualizar a lista de pacotes disponíveis
sudo apt update

# Baixar o Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.30.0/prometheus-2.30.0.linux-amd64.tar.gz
tar -xzf prometheus-2.30.0.linux-amd64.tar.gz
sudo mv prometheus-2.30.0.linux-amd64 /etc/prometheus
rm prometheus-2.30.0.linux-amd64.tar.gz

# Configurar o Prometheus
cat << EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhos:9090']
EOF

# Criar o diretório de armazenamento dos dados do Prometheus
sudo mkdir -p /var/lib/prometheus/data

# Alterar as permissões do diretório de armazenamento
sudo chown -R nobody:nogroup /var/lib/prometheus

# Criar o serviço do Prometheus
cat << EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Time Series Collection and Processing Server
Wants=network-online.target
After=network-online.target

[Service]
User=nobody
Group=nogroup
Type=simple
ExecStart=/etc/prometheus/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/data \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Recarregar os serviços do systemd
sudo systemctl daemon-reload

# Iniciar e habilitar o serviço do Prometheus
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Exibir informações de status do Prometheus
echo "Prometheus status:"
sudo systemctl status prometheus

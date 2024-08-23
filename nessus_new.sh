#bin/bash

token=$(curl -s -k -X POST -H "Content-Type: application/json" -d "{\"username\":\"docksec\",\"password\":\"owmYoPLLP9qkN7NotTIY\"}" https://192.168.28.140:8834/session | jq '.token')

# Verifica se o token foi obtido com sucesso
if [ -z "$token" ]; then
    echo "Erro ao obter o token. Verifique suas credenciais."
    exit 1
fi

echo "Token obtido com sucesso: $token"

# Iniciar o DAST
scan_uuid=$(curl -s -k -X POST -H "Content-Type: application/json" -H "X-Cookie: token=$token" https://192.168.28.140:8834/scans/12/launch | jq '.scan_uuid')

if [ -z "$scan_uuid" ]; then
    echo "Erro ao obter o token. Verifique suas credenciais."
    exit 1
fi

echo "DAST Iniciado"

# Iniciar o VM Scan

scan_vm=$(curl -s -k -X POST -H "Content-Type: application/json" -H "X-Cookie: token=$token" https://192.168.28.140:8834/scans/17/launch | jq '.scan_uuid')

if [ -z "$scan_vm" ]; then
    echo "Scan em no host não inciado"
    exit 1
fi

echo "Scan nas VMs iniciado"

# Status do Scan

curl -s -k -X GET -H "Content-Type: application/json" -H "X-Cookie: token=$token" https://192.168.28.140:8834/scans/12/status

#!/bin/bash

# Criar token
token=$(curl -s -k -X POST -H "Content-Type: application/json" -d "{\"username\":\"docksec\",\"password\":\"owmYoPLLP9qkN7NotTIY\"}" https://192.168.28.140:8834/session | jq -r '.token')

# Verifica se o token foi obtido com sucesso
if [ -z "$token" ]; then
    echo "Erro ao obter o token. Verifique suas credenciais."
    exit 1
fi

echo "Token obtido com sucesso: $token"

# Solicitar relatório
file_id=$(curl -s -k -X POST -H "Content-Type: application/json" -H "X-Cookie: token=$token" -d '{"format": "nessus"}' https://192.168.28.140:8834/scans/12/export | jq -r '.file')

# Verifica se o ID do download foi obtido com sucesso
if [ -z "$file_id" ]; then
    echo "Erro ao obter o ID do download do relatório."
    exit 1
fi

echo "ID do download do relatório obtido com sucesso: $file_id"

# Verificar status
while true; do

status=$(curl -s -k -X GET -H "Content-Type: application/json" -H "X-Cookie: token=$token" https://192.168.28.140:8834/scans/12/export/$file_id/status | jq -r '.status')

if [ "$status" == "ready" ]; then
        echo "O relatório está pronto para download."
break
        echo "O relatório ainda está sendo gerado. Aguarde..."
        sleep 10
fi
done
# Baixar relatório
curl -s -k -X GET -H "X-Cookie: token=$token" https://192.168.28.140:8834/scans/12/export/$file_id/download > /home/docksec/API/scan_report.nessus

# Verifica se o relatório foi baixado com sucesso
if [ $? -eq 0 ]; then
    echo "Relatório baixado com sucesso em /home/docksec/API/scan_report.nessus"
else
    echo "Erro ao baixar o relatório."
    exit 1
fi

# Upload DefectDojo
curl -s -k -X POST http://192.168.0.4:8080/api/v2/reimport-scan/ \
                        -H 'accept: application/json' \
                        -H 'Authorization: Token 6fc2aa245784571d63c26b4b16da08de5c639fe2' \
                        -H 'Content-Type: multipart/form-data' \
                        -F 'test=44' \
                        -F "file=@/home/docksec/API/scan_report.nessus;type=application/xml" \
                        -F 'scan_type=Tenable Scan' \
                        -F 'active=true' \
                        -F 'verified=true' \
                        -F 'tags=DAST'

# Solicitar relatório do Scan de VM
file_id=$(curl -s -k -X POST -H "Content-Type: application/json" -H "X-Cookie: token=$token" -d '{"format": "nessus"}' https://192.168.28.140:8834/scans/17/export | jq -r '.file')

# Verifica se o ID do download foi obtido com sucesso
if [ -z "$file_id" ]; then
    echo "Erro ao obter o ID do download do relatório."
    exit 1
fi

echo "ID do download do relatório obtido com sucesso: $file_id"

# Verificar status
while true; do

status=$(curl -s -k -X GET -H "Content-Type: application/json" -H "X-Cookie: token=$token" https://192.168.28.140:8834/scans/17/export/$file_id/status | jq -r '.status')

if [ "$status" == "ready" ]; then
        echo "O relatório está pronto para download."
break
        echo "O relatório ainda está sendo gerado. Aguarde..."
        sleep 10
fi
done
# Baixar relatório
curl -s -k -X GET -H "X-Cookie: token=$token" https://192.168.28.140:8834/scans/17/export/$file_id/download > /home/docksec/API/scan_report_vm.nessus

# Verifica se o relatório foi baixado com sucesso
if [ $? -eq 0 ]; then
    echo "Relatório baixado com sucesso em /home/docksec/API/scan_report_vm.nessus"
else
    echo "Erro ao baixar o relatório."
    exit 1
fi

# Upload DefectDojo
curl -s -k -X POST http://192.168.0.4:8080/api/v2/reimport-scan/ \
                        -H 'accept: application/json' \
                        -H 'Authorization: Token 6fc2aa245784571d63c26b4b16da08de5c639fe2' \
                        -H 'Content-Type: multipart/form-data' \
                        -F 'test=45' \
                        -F "file=@/home/docksec/API/scan_report_vm.nessus;type=application/xml" \
                        -F 'scan_type=Tenable Scan' \
                        -F 'active=true' \
                        -F 'verified=true' \
                        -F 'tags=VM'

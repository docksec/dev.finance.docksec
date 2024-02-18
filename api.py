from flask import Flask, jsonify, json

app = Flask(__name__)

@app.route('/vulnerabilities')
def get_vulnerabilities():
    with open('trivy_results.json', 'r') as f:
        data = json.load(f)

        # Acesso aos resultados específicos do JSON
        results = data.get('Results', [])

        # Criar um dicionário para contar as vulnerabilidades por severidade
        severity_counts = {'unknown': 0, 'negligible': 0, 'low': 0, 'medium': 0, 'high': 0, 'critical': 0}

        # Iterar sobre os resultados e contar as vulnerabilidades por severidade
        for result in results:
            vulnerabilities = result.get('Vulnerabilities', [])
            for vulnerability in vulnerabilities:
                severity = vulnerability.get('Severity', 'unknown').lower()  # Convertendo para minúsculas
                severity_counts[severity] += 1

        # Retornar os contadores de vulnerabilidades por severidade em formato JSON
        return jsonify(severity_counts)
        
@app.route('/vulnerabilities1')
def get_total_vulnerabilities():
    with open('trivy_results.json', 'r') as f:
        data = json.load(f)

    # Acesso aos resultados específicos do JSON
    results = data.get('Results', [])

    # Inicializa o contador de vulnerabilidades
    total_vulnerabilities = 0

    # Itera sobre os resultados e conta o total de vulnerabilidades
    for result in results:
        vulnerabilities = result.get('Vulnerabilities', [])
        total_vulnerabilities += len(vulnerabilities)

    # Retorna o total de vulnerabilidades em formato JSON
    return jsonify({'total_vulnerabilities': total_vulnerabilities})
    
@app.route('/vulnerabilities2')
def get_all_vulnerabilities():
    with open('trivy_results.json', 'r') as f:
        data = json.load(f)

    # Acesso aos resultados específicos do JSON
    results = data.get('Results', [])

    all_vulnerabilities = []

    # Iterar sobre os resultados e extrair os detalhes das vulnerabilidades
    for result in results:
        vulnerabilities = result.get('Vulnerabilities', [])
        for vulnerability in vulnerabilities:
            vulnerability_details = {
                'Alvo da Análise': result.get('Target', ''),
                'Nome do Pacote': vulnerability.get('PkgName', ''),
                'ID': vulnerability.get('VulnerabilityID', ''),
                'CVSS Score National Vulnerability Database': vulnerability.get('CVSS', {}).get('nvd', {}).get('V3Score', ''),
                'Tipo de Vulnerabilidade': vulnerability.get('DataSource', {}).get('Name', ''),
                'Data de Publicação': vulnerability.get('PublishedDate', ''),
                'Versão Corrigida': vulnerability.get('FixedVersion', ''),
                'Versão Instalada': vulnerability.get('InstalledVersion', ''),
                'Status': vulnerability.get('Status', ''),
                'Pubilicação': vulnerability.get('PrimaryURL', ''),
            }
            all_vulnerabilities.append(vulnerability_details)

    return jsonify(all_vulnerabilities)
		
@app.route('/metrics')
def get_metrics():
    with open('trivy_results.json', 'r') as f:
        data = json.load(f)

    # Acesso aos resultados específicos do JSON
    results = data.get('Results', [])

    # Criar dicionários separados para contar as vulnerabilidades do OS e das dependências
    os_vulnerabilities = {'Type': 'OS', 'critical': 0, 'high': 0, 'medium': 0, 'low': 0, 'negligible': 0, 'unknown': 0}
    dependency_vulnerabilities = {'Type': 'Dependency', 'critical': 0, 'high': 0, 'medium': 0, 'low': 0, 'negligible': 0, 'unknown': 0}

    # Iterar sobre os resultados e contar as vulnerabilidades por tipo
    for result in results:
        vulnerabilities = result.get('Vulnerabilities', [])
        for vulnerability in vulnerabilities:
            severity = vulnerability.get('Severity', 'Unknown').lower()
            if result.get('Class') == 'os-pkgs':
                os_vulnerabilities['Type'] = result.get('Type', 'Unknown')
                os_vulnerabilities[severity] += 1
            elif result.get('Class') == 'lang-pkgs':
                dependency_vulnerabilities['Type'] = result.get('Type', 'Unknown')
                dependency_vulnerabilities[severity] += 1

    # Retornar os contadores de vulnerabilidades por tipo em formato JSON
    return jsonify({'OS_vulnerabilities': os_vulnerabilities, 'Dependency_vulnerabilities': dependency_vulnerabilities})

if __name__ == '__main__':
  app.run(host='0.0.0.0', port=5000)

pipeline {
    agent {
        label 'dev'
    }

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        NESSUS_USERNAME = credentials ('Username')
        NESSUS_PASSWORD = credentials ('Password')
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Upload to DefectDojo') {
            steps {
                withCredentials (CredentialsID: 'Username', CredentialsID: 'Password',)
                script {      
                    sh """
                    // curl -X POST http://192.168.0.3:8080/api/v2/reimport-scan/ \
                    //     -H 'accept: application/json' \
                    //     -H 'Authorization: Token 4996cd1d669be523369593998f24df017539de4e' \
                    //     -H 'Content-Type: multipart/form-data' \
                    //     -F 'test=1' \
                    //     -F 'file=@/home/docksec/API/trivy_results.json;type=application/json' \
                    //     -F 'scan_type=Trivy Scan' \
                    //     -F 'tags=test'
                    
                    token=$(curl -s -k -X POST -H "Content-Type: application/json" -d "{\"username\":\"${NESSUS_USERNAME}\",\"password\":\"${NESSUS_PASSWORD}\"}" https://192.168.28.140:8834/session | jq -r '.token')
                    
                    if [ -z "$token" ]; then
                        echo "Erro ao obter o token. Verifique suas credenciais."
                        exit 1
                    fi
                    
                   echo "Token obtido com sucesso: $token"
                    
                   file_id=$(curl -s -k -X POST -H "Content-Type: application/json" -H "X-Cookie: token=$token" -d '{"format": "nessus"}' https://192.168.28.140:8834/scans/12/export | jq -r '.file')
                    
                   if [ -z "$file_id" ]; then
                        echo "Erro ao obter o ID do download do relatório."
                        exit 1
                    fi
                    
                    echo "ID do download do relatório obtido com sucesso: $file_id"
                    
                    while true; do
                    
                    status=$(curl -s -k -X GET -H "Content-Type: application/json" -H "X-Cookie: token=$token" https://192.168.28.140:8834/scans/12/export/$file_id/status | jq -r '.status')
                    
                    if [ "$status" == "ready" ]; then
                            echo "O relatório está pronto para download."
                    break
                            echo "O relatório ainda está sendo gerado. Aguarde..."
                            sleep 10
                    fi
                    done
                   
                    curl -s -k -X GET -H "X-Cookie: token=$token" https://192.168.28.140:8834/scans/12/export/$file_id/download > /home/docksec/API/scan_report.nessus
                    
                    if [ $? -eq 0 ]; then
                        echo "Relatório baixado com sucesso em /home/docksec/API/scan_report.nessus"
                    else
                        echo "Erro ao baixar o relatório."
                        exit 1
                    fi
                    
                    curl -s -k -X POST http://192.168.0.3:8080/api/v2/reimport-scan/ \
                                            -H 'accept: application/json' \
                                            -H 'Authorization: Token 4996cd1d669be523369593998f24df017539de4e' \
                                            -H 'Content-Type: multipart/form-data' \
                                            -F 'test=4' \
                                            -F "file=@/home/docksec/API/scan_report.nessus;type=application/xml" \
                                            -F 'scan_type=Tenable Scan' \
                                            -F 'tags=dast'
                    """
                }
            }
        }
        
        stage('Checkout from Git') {
            steps {
                git branch: 'master', url: 'https://github.com/docksec/dev.finance.docksec.git'
            }
        }

        stage('Sonarqube (SAST)') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=Dev.finance \
                        -Dsonar.projectKey=Dev.finance"""
                }
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install --package-lock'
            }
        }

        stage('Dependency Check (SCA)') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh 'docker build -t docksec:fixed2 .'
                        sh 'docker tag docksec:fixed2 docksec6/docksec:fixed2'
                        sh 'docker push docksec6/docksec:fixed2'
                    }
                }
            }
        }

        stage('Trivy (Container Scan)') {
            steps {
                sh 'trivy image docksec6/docksec:fixed2 > trivyimage.txt'
                sh 'trivy image -f json docksec6/docksec:fixed2 > /home/docksec/API/trivy_results.json'
            }
        }

        stage('Aguardar Aprovação') {
            steps {
                emailext (
                    subject: "Aprovação para Produção",
                    body: "Project: ${env.JOB_NAME}" +
                        "Build Number: ${env.BUILD_NUMBER}"+
                        "Clique no link para visualizar as vulnerabilidades no Grafana: (http://192.168.28.140:3000/d/fe3459f7-9809-448d-a580-b93c728e38b6/trivy?orgId=1)" +
                        "Clique no link para aprovação/reijeição do deploy em Produção: ${env.BUILD_URL}",
                    to: 'docksec6@gmail.com',
                    attachmentsPattern: 'trivyimage.txt',
                    attachLog: true
                )
                input message: 'Por favor, aprove o build para continuar', ok: 'Continuar'
            }
        }
    }

    post {
        always {
            emailext attachLog: true,
                subject: "'${currentBuild.result}'",
                body: "Project: ${env.JOB_NAME}<br/>" +
                    "Build Number: ${env.BUILD_NUMBER}<br/>" +
                    "URL: ${env.BUILD_URL}<br/>",
                to: 'docksec6@gmail.com',
                attachmentsPattern: 'trivyimage.txt'
        }
    }
}

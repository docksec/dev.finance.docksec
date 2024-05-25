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
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout from Git') {
            steps {
                git branch: 'master', url: 'https://github.com/docksec/dev.finance.docksec.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install --package-lock'
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
                        sh """
                        docker build -t docksec:fixed2 .
                        docker tag docksec:fixed2 docksec6/docksec:fixed2
                        docker push docksec6/docksec:fixed2
                        """
                    }
                }
            }
        }

        stage('Trivy (Container Scan)') {
            steps {
                sh """
                 trivy image docksec6/docksec:fixed2 > trivyimage.txt
                 trivy image -f json docksec6/docksec:fixed2 > /home/docksec/API/trivy_results.json
                 """
            }
        }
        
        stage('Upload to DefectDojo') {
            steps {
                script {
                    def defectDojoApiKey = credentials('DEFECTDOJO_API_KEY')
                    def defectDojoUrl = 'http://192.168.0.4:8080/api/v2/import-scan/'
                    def reportDPCheck = findFiles(glob: '**/dependency-check-report.xml')[0]
                    def reportTrivyPath = "/home/docksec/API/trivy_results.json"
                    def engagementId = '30'
                    
                    sh """
                    curl -s -k -X POST "${defectDojoUrl}" \
                        -H 'accept: application/json' \
                        -H 'Authorization: Token ${defectDojoApiKey}' \
                        -H 'Content-Type: multipart/form-data' \
                        -F 'engagement=${engagementId}' \
                        -F 'file=@${reportDPCheck.path};type=application/xml' \
                        -F 'scan_type=Dependency Check Scan' \
                        -F 'tags=SCA,dependency-check' \
                        -F 'active=true' \
                        -F 'verified=true' \
                        -F 'environment=Development' \
                        -F 'version=1.0.0'
                    """

                    sh """
                    curl -s -k -X POST "${defectDojoUrl}" \
                        -H 'accept: application/json' \
                        -H 'Authorization: Token ${defectDojoApiKey}' \
                        -H 'Content-Type: multipart/form-data' \
                        -F 'engagement=${engagementId}' \
                        -F 'file=@${reportTrivyPath};type=application/json' \
                        -F 'scan_type=Trivy Scan' \
                        -F 'tags=Container Scan,Trivy CLI' \
                        -F 'active=true' \
                        -F 'verified=true' \
                        -F 'environment=Development' \
                        -F 'version=1.0.0'
                    """
                    
                    sh """
                    ${nessus}/nessus_export.sh
                    """
                }
            }
        }
        
        stage('Deploy em Homologação') {
            agent {
                label 'hml'
            }
            environment {
                tag_version = "fixed2"
            }
            steps {
                script {
                    withAWS(credentials: 'aws', region: 'sa-east-1') {
                        sh 'docker pull docksec6/docksec:fixed2'
                        sh 'docker run -d --name docksec-fixed2 -p 8080:8080 docksec6/docksec:fixed2'
                    }
                }
            }
        }

        stage('Aguardar Aprovação') {
            steps {
               emailext (
                    subject: "Aprovação para Produção",
                    body: "Project: ${env.JOB_NAME}<br/>" +
                        "Build Number: ${env.BUILD_NUMBER}<br/>" +
                        "Clique no link para visualizar as vulnerabilidades no Grafana: (http://192.168.28.140:3000/d/fe3459f7-9809-448d-a580-b93c728e38b6/trivy?orgId=1)<br/>" +
                        "Clique no link para aprovação/rejeição do deploy em Produção: ${env.BUILD_URL}",
                    to: 'docksec6@gmail.com',
                    attachmentsPattern: 'trivyimage.txt',
                    attachLog: true
                )
                input message: 'Por favor, aprove o build para continuar', ok: 'Continuar'
            }
        }

        stage('Deploy em Produção') {
            agent {
                label 'prd'
            }
            environment {
                tag_version = "fixed2"
            }
            steps {
                script {
                    withAWS(credentials: 'aws', region: 'sa-east-1') {
                        sh 'docker pull docksec6/docksec:fixed2'
                        sh 'docker run -d --name docksec-fixed2 -p 8080:8080 docksec6/docksec:fixed2'
                    }
                }
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

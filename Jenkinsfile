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
        
        stage('Upload to DefectDojo') {
            steps {
                script {      
                    sh """
                    ${nessus}./nessus_export.sh
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

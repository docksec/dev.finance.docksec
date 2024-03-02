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
                        def runningContainer = sh(script: 'docker ps -a --format "{{.Names}}" | grep docksec-fixed2', returnStdout: true).trim()
        
                        if (runningContainer) {
                            sh 'docker stop docksec-fixed2'
                            sh 'docker rm docksec-fixed2'
                        } else {
                            echo 'O contêiner docksec-fixed2 não está em execução. Continuando com o deploy...'
                        }
                        sh 'docker pull docksec6/docksec:fixed2'
                        sh 'docker run -d --name docksec-fixed2 -p 8080:8080 docksec6/docksec:fixed2'
                    }
                }
            }
        }

        stage('Aguardar Aprovação') {
            steps {
                input message: 'Por favor, aprove o build para continuar', ok: 'Continuar'
        
                // Envio de e-mail no meio do segundo estágio
                emailext (
                    subject: "'${currentBuild.result}'",
                    body: "Project: ${env.JOB_NAME}/n" +
                        "Build Number: ${env.BUILD_NUMBER}/n" +
                        "Clique no link para visualizar as vulnerabilidades no Grafana: (http://192.168.28.140:3000/d/fe3459f7-9809-448d-a580-b93c728e38b6/trivy?orgId=1) /n" +
                        "Clique no link para aprovação/reijeição do deploy em Produção: ${env.BUILD_URL}/n",
                    to: 'docksec6@gmail.com',
                    attachmentsPattern: 'trivyimage.txt', // Adicione a vírgula aqui
                    attachLog: true
                )
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

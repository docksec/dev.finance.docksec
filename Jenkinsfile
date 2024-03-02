pipeline {
    agent{
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
            agent {
                label 'dev'
            }
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            agent {
                label 'dev'
            }
            steps {
                git branch: 'master', url: 'https://github.com/docksec/dev.finance.docksec.git'
            }
        }
        
        stage('Sonarqube (SAST)') {
            agent {
                label 'dev'
            }
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """$SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Dev.finance \
                        -Dsonar.projectKey=Dev.finance"""
                }
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        
        stage('Install Dependencies') {
            agent {
                label 'dev'
            }
            steps {
                sh 'npm install --package-lock'
            }
        }

        stage('Dependency Check (SCA)') {
            agent {
                label 'dev'
            }
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Docker Build & Push') {
            agent {
                label 'dev'
            }
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
            agent {
                label 'dev'
            }
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
                        sh 'docker stop docksec-fixed2'
                        sh 'docker rm docksec-fixed2'
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
        stage('Aguardar Aprovação') {
                steps {
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
                        sh 'docker stop docksec-fixed2'
                        sh 'docker rm docksec-fixed2'
                        sh 'docker pull docksec6/docksec:fixed2'
                        sh 'docker run -d --name docksec-fixed2 -p 8080:8080 docksec6/docksec:fixed2'
                    }
                }
            }
        }
}

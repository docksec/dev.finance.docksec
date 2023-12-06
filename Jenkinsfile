pipeline {
    agent{
        label 'agentLocal'
        label 'agentAWS'
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
                label 'agentLocal'
            }
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            agent {
                label 'agentLocal'
            }
            steps {
                git branch: 'master', url: 'https://github.com/docksec/dev.finance.docksec.git'
            }
        }

        stage('Sonarqube (SAST)') {
            agent {
                label 'agentLocal'
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
                label 'agentLocal'
            }
            steps {
                sh 'npm install'
            }
        }

        stage('Dependency Check (SCA)') {
            agent {
                label 'agentLocal'
            }
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Docker Build & Push') {
            agent {
                label 'agentLocal'
            }
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh 'docker build -t docksec:latest .'
                        sh 'docker tag docksec:latest docksec6/docksec:latest'
                        sh 'docker push docksec6/docksec:latest'
                    }
                }
            }
        }

        stage('Container Scan') {
            agent {
                label 'agentLocal'
            }
            steps {
                sh 'trivy image docksec6/docksec:latest > trivyimage.txt'
            }
        }

        stage('Deploy em Homologação') {
            agent {
                label 'agentAWS'
            }
            environment {
                tag_version = "latest"
            }

            steps {
                script {
                    withAWS(credentials: 'AWS', region: 'sa-east-1') {
                        sh 'docker pull docksec6/docksec:latest'
                        sh 'docker build -t docksec:latest .'
                        sh 'docker run -d --name docksec-latest -p 8080:8080 docksec6/docksec:latest'
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
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}

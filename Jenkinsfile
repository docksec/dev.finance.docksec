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
                sh 'npm install'
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
                        sh 'docker build -t docksec:latest .'
                        sh 'docker tag docksec:latest docksec6/docksec:latest'
                        sh 'docker push docksec6/docksec:latest'
                    }
                }
            }
        }

        stage('Container Scan') {
            agent {
                label 'dev'
            }
            steps {
                sh 'trivy image docksec6/docksec:latest > trivyimage.txt'
                sh 'trivy image -f json docksec6/docksec:latest > /home/docksec/API/trivy_results.json'
            }
        }

        stage('Deploy em Homologação') {
            agent {
                label 'hml'
            }
            environment {
                tag_version = "latest"
            }

            steps {
                script {
                    withAWS(credentials: 'aws', region: 'sa-east-1') {
                        sh 'docker stop docksec-latest'
                        sh 'docker rm docksec-latest'
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

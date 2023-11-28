pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                script {
                    docker.build("docksec6/docksec:${env.BUILD_ID}", "-f ./Dockerfile .")
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub') {
                        docker.image("docksec6/docksec:${env.BUILD_ID}").push()
                    }
                }
            }
        }
        
        stage('Deploy no ambiente de Dev na AWS') {
            steps {
                script {
                    withAWS(credentials: 'awsdocksec', region: 'sa-east-1') {
                        sh "trivy image docksec6/docksec:v1 > scan.txt"
                    }
                }
            }
        }
    }
}
    }
}



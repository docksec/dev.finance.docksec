pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                script {
                    sh 'npm install'
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
                        sh "docker pull docksec6/docksec:${env.BUILD_ID}"
                        sh "docker run -d -p 80:8080 docksec6/docksec:${env.BUILD_ID}"
                        // A exposição de portas através do Dockerfile e 'EXPOSE' geralmente não é necessária aqui.
                        sh "npx live-server"
                    }
                }
            }
        }
    }
}



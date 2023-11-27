pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                script {
                    // Construir a imagem Docker
                    docker.build("docksec6/docksec:${env.BUILD_ID}", "-f ./Dockerfile ./")
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    // Autenticar no Docker Hub
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub') {
                        // Empurrar a imagem para o Docker Hub
                        docker.image("docksec6/docksec:${env.BUILD_ID}").push()
                    }
                }
            }
        }
    }
}

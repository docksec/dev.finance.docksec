pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                script {
                    // Construir a imagem Docker
                    docker.build("docksec6/docksec:${env.BUILD_ID}", "-f ./Dockerfile .")
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
        stage('Deploy no ambiente de Dev na AWS'){
            steps{
             // Configurar credenciais AWS
            withAWS(credentials: 'awsdocksec', region: 'sa-east-1') {
            // Baixar container do Docker Hub com a tag '12'
                docker.image("docksec6/docksec:12").pull()

            // Construir e executar o container na porta 80
                docker.image("docksec6/docksec:12").run("-p", "80:8080")
                }
            }
        }
    }
}


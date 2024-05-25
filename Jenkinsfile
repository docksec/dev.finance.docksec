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

        stage('Upload to DefectDojo') {
            steps {
                script {
                        def defectDojoApiKey = credentials('DEFECTDOJO_API_KEY')
                        def defectDojoUrl = 'https://192.168.0.4:8080/api/v2/import-scan/'
                        def reportDP-Check = findFiles(glob: '**/dependency-check-report.xml')[0]
                        def reportTrivy = findFiles(glob: '${trivy}/trivy_results.json')[0]
                        def engagementId = '30'
            
                        def DP Check = """
                        {
                            "scan_type": "Dependency Check Scan",
                            "engagement": ${engagementId},
                            "file": null,
                            "active": true,
                            "verified": true,
                            "scan_date": "${new Date().format('yyyy-MM-dd')}",
                            "tags": "jenkins,dependency-check",
                            "minimum_severity": "Low",
                            "close_old_findings": true,
                            "push_to_jira": false,
                            "environment": "Development",
                            "version": "1.0.0"
                        }
                        """
            
                        httpRequest acceptType: 'APPLICATION_JSON',
                                    contentType: 'MULTIPART_FORM_DATA',
                                    httpMode: 'POST',
                                    requestBody: DP Check,
                                    responseHandle: 'STRING',
                                    url: defectDojoUrl,
                                    customHeaders: [
                                        [name: 'Authorization', value: "Token ${defectDojoApiKey}"]
                                    ],
                                    uploadFile: reportDP-Check.path,
                                    multipartName: 'file'     

                    def Trivy CLI = """
                        {
                            "scan_type": "Trivy Scan",
                            "engagement": ${engagementId},
                            "file": null,
                            "active": true,
                            "verified": true,
                            "scan_date": "${new Date().format('yyyy-MM-dd')}",
                            "tags": "jenkins,Trivy CLI",
                            "minimum_severity": "Low",
                            "close_old_findings": true,
                            "push_to_jira": false,
                            "environment": "Development",
                            "version": "1.0.0"
                        }
                        """
                    
                            httpRequest acceptType: 'APPLICATION_JSON',
                                        contentType: 'MULTIPART_FORM_DATA',
                                        httpMode: 'POST',
                                        requestBody: Trivy CLI,
                                        responseHandle: 'STRING',
                                        url: defectDojoUrl,
                                        customHeaders: [
                                            [name: 'Authorization', value: "Token ${defectDojoApiKey}"]
                                        ],
                                        uploadFile: reportTrivy.path,
                                        multipartName: 'file'    
                    
                    sh """
                    ${nessus}/nessus_export.sh
                    """
                }
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
                 trivy image -f json docksec6/docksec:fixed2 > ${trivy}/trivy_results.json
                 """
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

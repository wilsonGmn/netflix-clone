pipeline {
    agent any
    tools {
        jdk 'jdk' // Ensure 'jdk' is correctly configured in Jenkins
        nodejs 'node' // Ensure 'node' is correctly configured in Jenkins
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner' // Ensure 'sonar-scanner' is correctly configured in Jenkins
        GIT_REPO_NAME = "DevSecOps-Project"
        GIT_USER_NAME = "wilsonGmn"
    }
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Test ENV') {
            steps {
                sh '''
                    docker version
                    whoami
                    echo $HOSTNAME
                '''
            }
        }
        
        stage('Test Node') {
            steps {
                script {
                    docker.image('node:20').inside {
                        sh 'node --version'
                        sh 'npm --version'
                    }
                }
            }
        }
        stage('Checkout from Git') {
            steps {
                withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        git clone https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}.git
                    '''
                }
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Netflix \
                    -Dsonar.projectKey=Netflix'''
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                dir('DevSecOps-Project') {
                sh '''
                    ls -l
                    npm install
                '''
                }
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                
                dir('DevSecOps-Project') {
                    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'dp-check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                dir('DevSecOps-Project') {
                    script {
                        // Run Trivy using Docker executor
                        docker.image('aquasec/trivy:0.36.0').inside('--entrypoint=""') {
                            sh '''
                                # Define a custom cache directory within the project workspace
                                export TRIVY_CACHE_DIR=$(pwd)/.trivy-cache
                                
                                # Create the cache directory if it doesn't exist
                                mkdir -p $TRIVY_CACHE_DIR
                                
                                # Perform Trivy scan on the current directory with the custom cache directory
                                trivy fs --cache-dir $TRIVY_CACHE_DIR . > trivyfs.txt
                                
                                # Display the scan results
                                cat trivyfs.txt
                            '''
                        }
                    }
                }
            }
        }
        stage("Docker Build & Push") {
            steps {
                dir('DevSecOps-Project') {
                    script {
                        // Use withCredentials to inject the API key securely
                        withCredentials([string(credentialsId: 'tmdb-api-key', variable: 'TMDB_V3_API_KEY')]) {
                            withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                                // Build the Docker image with the API key
                                sh "docker build --build-arg TMDB_V3_API_KEY=${TMDB_V3_API_KEY} -t netflix ."
                                // Tag the Docker image
                                sh "docker tag netflix ${DOCKER_IMAGE}"
                                // Push the Docker image to the registry
                                sh "docker push ${DOCKER_IMAGE}"
                            }
                        }
                    }
                }
            }
        }
        stage("TRIVY") {
            steps {
                // Scan the Docker image with Trivy
                sh "trivy image ${DOCKER_IMAGE} > trivyimage.txt"
                // Archive the Trivy scan results as an artifact
                archiveArtifacts artifacts: 'trivyimage.txt', allowEmptyArchive: true
            }
        }
        stage('Deploy to Container') {
            steps {
                // Run the Docker container
                sh 'docker run -d -p 8081:80 ${DOCKER_IMAGE}'
            }
        }
    }
}

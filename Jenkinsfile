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
        stage('Test') {
            steps {
                sh '''
                    java -version
                    docker version
                    whoami
                    echo $HOSTNAME
                '''
            }
        }
        
        stage('Java') {
            steps {
                script {
                    docker.image('maven:3.3.3-jdk-8').inside {
                      sh 'mvn -version'
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
    }
}

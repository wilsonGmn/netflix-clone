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
        DOCKER_IMAGE = 'wilsongmn/netflix:latest'
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
        stage("TRIVY IMAGE SCAN") {
            steps {
                script {
                    // Define Trivy Docker image and result file
                    def trivyImage = 'aquasec/trivy:0.36.0'
                    def resultsFile = 'trivyimage.txt'
                    def cacheDir = '.trivy-cache'
                    
                    // Run Trivy scan inside Docker container
                    docker.image(trivyImage).inside('--entrypoint=""') {
                        // Ensure the cache directory is created and used
                        sh """
                            # Set up a custom cache directory
                            export TRIVY_CACHE_DIR=\$(pwd)/${cacheDir}
                            
                            # Create the cache directory if it doesn't exist
                            mkdir -p \${TRIVY_CACHE_DIR}
                            
                            # Run Trivy scan and direct the output to a file
                            trivy --cache-dir \${TRIVY_CACHE_DIR} image ${DOCKER_IMAGE} > ${resultsFile}
                            
                            # Check if Trivy encountered any issues and report them
                            if [ \$? -ne 0 ]; then
                                echo "Trivy scan failed. Please check the logs for details."
                                exit 1
                            fi
                        """
                    }
                    
                    // Archive the Trivy scan results
                    archiveArtifacts artifacts: resultsFile, allowEmptyArchive: true
                }
            }
        }
        stage('Deploy to Container') {
            steps {
                script {
                    // Run the Docker container and get the container ID
                    def containerId = sh(
                        script: 'docker run -d -p 8081:80 ${DOCKER_IMAGE}',
                        returnStdout: true
                    ).trim()

                    // Wait for the service to be available (e.g., an HTTP service)
                    retry(3) {
                        sleep(time: 10, unit: 'SECONDS') // Wait 10 seconds before retrying
                        sh "curl --fail http://localhost:8081 || exit 1"
                    }

                    // If the service is available, print a success message
                    echo "Service is available at http://localhost:8081"

                    // Stop the Docker container after the check
                    sh "docker stop ${containerId}"
                }
            }
        }
        stage('K8s Dev Deploy') {
            agent {
                docker {
                    image 'alpine:3.7'
                }
            }
            environment {
                HOST = "cluster.local"
                PORT = "8443"
                KUBECONFIG = credentials('kubeconfig')  // Jenkins secret for kubeconfig
            }
            steps {
                script {
                    // Install kubectl
                    sh '''
                        wget https://storage.googleapis.com/kubernetes-release/release/$(wget -q -O - https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
                        chmod +x ./kubectl
                        mv ./kubectl /usr/bin/kubectl
                    '''

                    // Install netcat and gettext
                    sh '''
                        apk add --no-cache netcat-openbsd
                        apk add --no-cache gettext
                    '''

                    // Verify envsubst installation
                    sh 'envsubst -V'

                    // Test connection to Kubernetes cluster
                    sh '''
                        echo "Testing connection to $HOST:$PORT"
                        nc -z -w 5 $HOST $PORT
                        if [ $? -ne 0 ]; then 
                            echo "Host $HOST:$PORT is not reachable."; 
                            exit 1; 
                        else 
                            echo "Host $HOST:$PORT is reachable."; 
                        fi
                    '''

                    // Set KUBECONFIG and perform the deployment
                    withEnv(["KUBECONFIG=${KUBECONFIG}"]) {
                        sh '''
                            kubectl version -o yaml
                            kubectl config get-contexts
                            kubectl get nodes
                        '''
                    }
                }
            }
        }
    }
}



    environment  {
        SCANNER_HOME=tool 'sonar-server'
        SONARQUBE_TOKEN = credentials('sonar-token')
    }


    environment {
        SCANNER_HOME = tool 'SonarQubeScanner'
    }


    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }


        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh "${SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectName=Netflix1.0 \
                    -Dsonar.projectKey=Netflix1.0 \
                    -Dsonar.login=admin \
                    -Dsonar.password=M4NAg3r."
                }
            }
        }
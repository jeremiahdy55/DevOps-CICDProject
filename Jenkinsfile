pipeline {
    agent any

    environment {
        GIT_CREDENTIALS = 'github_credentials'
        REPO_URL        = 'https://github.com/jeremiahdy55/DevOps-CICDProject.git' // Github project monorepo
    }

    // **tools** must be setup in Jenkins-Tools config
    // Because this project doesn't require different maven/jdk versions,
    // maven and jdk will be installed during intialization using terraform's user_data block
    // tools {
    //     maven 'Maven_3.8.7' 
    //     jdk 'jdk17'
    // }

    stages {
        stage('Checkout') {
            steps {
                git credentialsId: "${env.GIT_CREDENTIALS}", url: "${env.REPO_URL}", branch: 'main'
            }
        }

        stage('Build and Push Microservices') {
            // use matrix for parallel processing (build and push all images concurrently)
            matrix {
                axes {
                    axis {
                        name: 'SERVICE'
                        values: 'order-ms', 'delivery-ms', 'payment-ms', 'stock-ms'
                    }
                }

                stages {
                    stage('Build JAR') {
                        steps {
                            dir("${SERVICE}") {
                                sh 'mvn clean package -DskipTests'
                            }
                        }
                    }

                    stage('Build Docker Image') {
                        steps {
                            withCredentials([usernamePassword(
                                credentialsId: 'docker_credentials',
                                usernameVariable: 'DOCKER_USER',
                                passwordVariable: 'DOCKER_PASS'
                            )]) {
                                dir("${SERVICE}") {
                                    sh """
                                        docker build -t $DOCKER_USER/${SERVICE}:latest .
                                    """
                                }
                            }
                        }
                    }

                    stage('Push Docker Image') {
                        steps {
                            withCredentials([usernamePassword(
                                credentialsId: 'docker_credentials',
                                usernameVariable: 'DOCKER_USER',
                                passwordVariable: 'DOCKER_PASS'
                            )]) {
                                sh """
                                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                                    docker push $DOCKER_USER/${SERVICE}:latest
                                """
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'All microservices built and pushed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}

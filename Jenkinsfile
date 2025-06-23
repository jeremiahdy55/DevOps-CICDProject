pipeline {
    agent any

    environment {
        GIT_CREDENTIALS = 'github_credentials'
        REPO_URL        = 'https://github.com/jeremiahdy55/DevOps-CICDProject.git' // Github project monorepo
        CLUSTER_NAME    = 'my-eks-cluster' // hard-coded, make sure this matches whatever is in terraform scripts
        AWS_REGION      = 'us-west-2' // hard-coded, make sure this matches whatever is in terraform scripts
    }

    // **tools** must be setup in Jenkins-Tools config
    // Because this project doesn't require different maven/jdk versions,
    // maven and jdk will be installed during intialization using terraform's user_data block
    // tools {
    //     maven 'Maven_3.8.7' 
    //     jdk 'jdk17'
    // }

    stages {
        stage('Load S3 bucket name from /etc/environment') {
            steps {
                script {
                    def s3Bucket = sh(script: "grep '^S3_BUCKET=' /etc/environment | cut -d '=' -f2", returnStdout: true).trim()
                    env.S3_BUCKET = s3Bucket
                    echo "Loaded S3_BUCKET from /etc/environment: ${env.S3_BUCKET}"
                }
            }
        }
        
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
                        name 'SERVICE'
                        values 'order-ms', 'delivery-ms', 'payment-ms', 'stock-ms'
                    }
                }

                stages {
                    stage('Inject Kafka IP') {
                        steps {
                            dir("${SERVICE}") {
                               sh """
                                # Fetch Kafka IP from S3
                                aws s3 cp s3://$S3_BUCKET/kafka_ip.txt kafka_ip.txt
                                KAFKA_IP=\$(cat kafka_ip.txt)

                                # Inject into application.properties
                                sed -i "s/^spring.kafka.bootstrap-servers=.*/spring.kafka.bootstrap-servers=\${KAFKA_IP}:9092/" src/main/resources/application.properties
                               """
                            }
                        }
                    }

                    stage('Build JAR') {
                        steps {
                            dir("${SERVICE}") {
                               sh  'mvn clean package -DskipTests'
                            }
                        }
                    }

                    stage('Build Docker Image') {
                        steps {
                            withCredentials([usernamePassword(
                                credentialsId: 'docker_hub_credentials',
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
                                credentialsId: 'docker_hub_credentials',
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
            echo 'All microservices built and pushed successfully! Proceeding to deploy to EKS.'

            script {
                // Configure kubectl
                sh """
                    set -e
                    aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
                    kubectl get nodes
                """

                // Loop through services and deploy
                def services = ['order-ms', 'delivery-ms', 'payment-ms', 'stock-ms']
                services.each { svc ->
                    dir("${svc}/k8s") {
                        sh "kubectl apply -f deployment.yaml"
                        sh "kubectl apply -f service.yaml"
                        sh "kubectl rollout status deployment/${svc} || true"
                    }
                }
            }
        }

        failure {
            echo 'Pipeline failed before deployment.'
        }
    }
}
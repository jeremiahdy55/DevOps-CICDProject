## Define the ec2 instances to be provisioned by terraform: Jenkins instance, Kafka instance
resource "aws_instance" "jenkins" {
  ami                         = var.ami_id
  instance_type               = var.instance_type_medium
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.default.id]
#   key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name

  # Run these commands on creation
  user_data = <<-EOF
              #!/bin/bash

              sleep 30

              exec > /var/log/jenkins-data.log 2>&1 

              # System update
              sudo apt update -y
              sudo apt upgrade -y

              # Install Java 17, Maven, unzip, and Docker for Jenkins to run (Git is also here just in case)
              sudo apt install -y openjdk-17-jdk maven unzip docker.io git gnupg software-properties-common curl

              # Start Docker
              sudo systemctl start docker
              sudo systemctl enable docker

              # Install Terraform
              curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
              echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
              sudo apt update -y
              sudo apt install -y terraform

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              sudo chmod +x kubectl
              sudo mv kubectl /usr/local/bin/

              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              sudo rm -rf awscliv2.zip aws/

              # Add Jenkins repo and import GPG key
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

              # Install Jenkins
              sudo apt update -y
              sudo apt install -y jenkins

              # Enable Jenkins to use Docker (*user:jenkins can use Docker)
              sudo usermod -aG docker jenkins

              # Add S3_bukcet file name as environment variable
              echo "S3_BUCKET=${aws_s3_bucket.ci_config_bucket.bucket}" | sudo tee -a /etc/environment

              # Enable and start Jenkins
              sudo systemctl enable jenkins
              sudo systemctl start jenkins

              # Restart Jenkins just to make sure Jenkins can use Docker after (sudo usermod -aG docker jenkins)
              sleep 30
              sudo systemctl restart jenkins
              EOF

  tags = {
    Name = "Jenkins-Server-fromTF"
    Role = "jenkins"
  }

  root_block_device {
    volume_size = 24   # 24 GB Storage
    volume_type = "gp3"
  }

  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table_association.public_assoc,
    aws_s3_bucket.ci_config_bucket
  ]
}

resource "aws_instance" "kafka" {
  ami                         = var.ami_id
  instance_type               = var.instance_type_medium
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.default.id]
#   key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # Run these commands on creation
  user_data = <<-EOF
              #!/bin/bash

              exec > >(tee /tmp/user_data.log|logger -t user_data -s 2>/dev/console) 2>&1

              sleep 30

              # Update system
              sudo apt update -y
              sudo apt upgrade -y

              # Install Java 17 for Jenkins to run
              sudo apt install -y openjdk-17-jdk

              # Create kafka user if not exists
              sudo id -u kafka &>/dev/null || sudo useradd -m -s /bin/bash kafka

              # Download the Kafka zip, unzip the file, and move it to the kafka directory and add permissions
              sudo apt install -y wget curl
              sudo wget https://archive.apache.org/dist/kafka/3.7.0/kafka_2.13-3.7.0.tgz -O /tmp/kafka.tgz
              mkdir -p /opt/kafka
              sudo tar -xzf /tmp/kafka.tgz -C /opt
              sudo mv /opt/kafka_2.13-3.7.0/* /opt/kafka/
              sudo rm -rf /opt/kafka_2.13-3.7.0
              chown -R kafka:kafka /opt/kafka            

              # Start Kafka Zookeeper as kafka user
              sudo -u kafka nohup /opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties > /tmp/zookeeper.log 2>&1 &

              # Sleep for a bit to allow Zookeeper to start
              sleep 30

              # Start Kafka Server as kafka user
              sudo -u kafka nohup /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties > /tmp/kafka.log 2>&1 &

              # Sleep for a bit to allow Kafka broker to start
              sleep 30
              
              # Create the Kafka topics
              sudo -u kafka /opt/kafka/bin/kafka-topics.sh --create --topic new-stock --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
              sudo -u kafka /opt/kafka/bin/kafka-topics.sh --create --topic reversed-stock --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
              sudo -u kafka /opt/kafka/bin/kafka-topics.sh --create --topic new-orders --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
              sudo -u kafka /opt/kafka/bin/kafka-topics.sh --create --topic reversed-orders --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
              sudo -u kafka /opt/kafka/bin/kafka-topics.sh --create --topic new-payments --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
              sudo -u kafka /opt/kafka/bin/kafka-topics.sh --create --topic reversed-payments --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1

              EOF

  tags = {
    Name = "Kafka-Server-fromTF"
    Role = "kafka"
  }

  root_block_device {
    volume_size = 24 # 24 GB Storage
    volume_type = "gp3"
  }

  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table_association.public_assoc
  ]
}


# Previous code to provision ec2 instances for microservices, moved this responsibility to EKS cluster
# locals {
#   microservices = ["delivery-ms", "order-ms", "payment-ms", "stock-ms"]
# }

# resource "aws_instance" "microservice" {
#   for_each = toset(local.microservices)

#   ami                         = var.ami_id
#   instance_type               = var.instance_type_micro
#   subnet_id                   = aws_subnet.public.id
#   vpc_security_group_ids      = [aws_security_group.default.id]
# #   key_name                    = aws_key_pair.deployer.key_name
#   associate_public_ip_address = true

#   # Run these commands on creation
#   user_data = <<-EOF
#               #!/bin/bash
#               sleep 30
#               sudo apt update -y
#               sudo apt upgrade -y
#               EOF

#   tags = {
#     Name = each.key
#     Role = "microservice"
#   }

#   depends_on = [
#     aws_internet_gateway.igw,
#     aws_route_table_association.public_assoc
#   ]
# }
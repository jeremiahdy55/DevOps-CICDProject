## Define the ec2 instances to be provisioned by terraform: ms instances, Jenkins instance, Kafka instance

locals {
  microservices = ["delivery-ms", "order-ms", "payment-ms", "stock-ms"]
}

resource "aws_instance" "microservice" {
  for_each = toset(local.microservices)

  ami                         = var.ami_id
  instance_type               = var.instance_type_micro
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.default.id]
#   key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # Run these commands on creation
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt upgrade -y
              EOF

  tags = {
    Name = each.key
    Role = "microservice"
  }

  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table_association.public_assoc
  ]
}

resource "aws_instance" "jenkins" {
  ami                         = var.ami_id
  instance_type               = var.instance_type_medium
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.default.id]
#   key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # Run these commands on creation TODO fix me later
  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/jenkins-data.log 2>&1 

              # System update
              sudo apt update -y
              sudo apt upgrade -y

              # Install Java 17 for Jenkins to run
              sudo apt install -y openjdk-17-jdk

               # Add Jenkins repo and import GPG key
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null

              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null

              # Install Jenkins
              apt update -y
              apt install -y jenkins

              # Enable and start Jenkins
              systemctl enable jenkins
              systemctl start jenkins

              sudo 
              EOF

  tags = {
    Name = "Jenkins-Server-fromTF"
    Role = "jenkins"
  }

  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table_association.public_assoc
  ]
}

resource "aws_instance" "kafka" {
  ami                         = var.ami_id
  instance_type               = var.instance_type_medium
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.default.id]
#   key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # Run these commands on creation TODO fix me later
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt upgrade -y
              EOF

  tags = {
    Name = "Kafka-Server-fromTF"
    Role = "kafka"
  }

  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table_association.public_assoc
  ]
}

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

  tags = {
    Name = "Kafka-Server-fromTF"
    Role = "kafka"
  }

  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table_association.public_assoc
  ]
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "kafka_public_ip" {
  value = aws_instance.kafka.public_ip
}

output "microservices_public_ips" {
  value = { for key, ms in aws_instance.microservice : ms => value.public_ip }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}
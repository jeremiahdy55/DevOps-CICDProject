# IAM Role for Jenkins EC2 Instance to Access EKS and Other AWS Services
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach Required Policies (EKS Full Access, EC2, IAM, VPC, CloudFormation for cluster bootstrap)
resource "aws_iam_role_policy_attachment" "eks_full_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudformation_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
}

# resource "aws_iam_role_policy_attachment" "ecr_access" {
#   role       = aws_iam_role.jenkins_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
# }

# Create IAM Instance Profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-ec2-instance-profile"
  role = aws_iam_role.jenkins_role.name
}
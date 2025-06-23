provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint

  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
  }
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.jenkins_role.arn
        username = "jenkins"
        groups   = ["system:masters"]
      },
      # Add existing worker node roles here too, to avoid overwriting
      {
        rolearn  = aws_iam_role.eks_nodegroup_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role.jenkins_role,
    aws_iam_role.eks_nodegroup_role,]
}
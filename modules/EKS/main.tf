#create EKS Cluster eks_cluster

resource "aws_eks_cluster" "eks_cluster" {
  name = var.PROJECT_NAME

  # The Amazon Resource Name (ARN) of the IAM role that provides permissions for the Kubernetes control plane to make calls to AWS API operations

  role_arn = var.EKS_CLUSTER_ROLE_ARN
  # Desired Kubernetes master version
  version = "1.27"
  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    subnet_ids = [
      var.PUB_SUB1_ID,
      var.PUB_SUB2_ID,
      var.PRI_SUB3_ID,
      var.PRI_SUB4_ID
    ]
  }
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  #  url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  #  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  #  url             = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}
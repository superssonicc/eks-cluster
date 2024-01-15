data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks-cluster-1.identity[0].oidc[0].issuer
  #  url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  #  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url = aws_eks_cluster.eks-cluster-1.identity[0].oidc[0].issuer
  #  url             = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}


data "aws_iam_policy_document" "csi" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      #      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_ebs_csi_driver" {
  assume_role_policy = data.aws_iam_policy_document.csi.json
  name               = "eks-ebs-csi-driver"
}

resource "aws_iam_role_policy_attachment" "amazon_ebs_csi_driver" {
  role       = aws_iam_role.eks_ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


# use "aws eks describe-addon-versions --addon-name aws-ebs-csi-driver" command to find out latest version and copy it to below script. this script will install CSI driver
resource "aws_eks_addon" "csi_driver" {
  cluster_name = aws_eks_cluster.eks-cluster-1.name
  #  cluster_name             = aws_eks_cluster.demo.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.21.0-eksbuild.1"
  #  addon_version            = "v1.11.4-eksbuild.1"
  service_account_role_arn = aws_iam_role.eks_ebs_csi_driver.arn
}
locals {
  alb_ingress_controller = {
    namespace            = "alb-ingress-controller"
    service_account_name = "alb-ingress-controller"
  }
}

module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "alb-controller-${var.nuon_id}"

  create_role                            = true
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    k8s = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${local.alb_ingress_controller.namespace}:${local.alb_ingress_controller.service_account_name}"]
    }
  }

  tags = var.tags
}

# values: https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/v2.15.0/helm/aws-load-balancer-controller/values.yaml
# issue: https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/4307
resource "helm_release" "alb_ingress_controller" {
  namespace        = local.alb_ingress_controller.namespace
  create_namespace = true

  name       = "alb-ingress-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.9.2"

  set = [
    {
      name  = "region"
      value = var.region

    },
    {
      name  = "vpcId"
      value = var.vpc_id

    },
    {
      name  = "enableCertManager"
      value = "apply"
    },
    {
      name  = "clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "rbac.create"
      value = "true"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = local.alb_ingress_controller.service_account_name
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.alb_controller_irsa.iam_role_arn
    },
    { // we only set this one tag in case any of the others (in local.tags) conflict.
      name  = "defaultTags.nuon_install_id"
      value = var.nuon_id
    },
    {
      name  = "defaultTags.install\\.nuon\\.co\\/id"
      value = var.nuon_id
    },
    { // we only set this one tag in case any of the others (in local.tags) conflict.
      name  = "defaultTags.created_by"
      value = "alb-ingress-controller"
    }
  ]

  depends_on = [
    helm_release.cert_manager,
    module.alb_controller_irsa,
  ]
}

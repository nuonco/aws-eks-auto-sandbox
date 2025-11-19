locals {
  internal_domain = aws_route53_zone.internal.name
  public_domain   = aws_route53_zone.public.name
  external_dns = {
    namespace = "external-dns"
    name      = "external-dns"
    extra_args = {
      0 = "--publish-internal-services",
      1 = "--zone-id-filter=${aws_route53_zone.internal.id}",
      2 = "--zone-id-filter=${aws_route53_zone.public.id}",
    }
    value_file = "${path.module}/values/external-dns.yaml"
  }

  # Convert extra_args map to set format
  extra_args_set = [
    for key, value in local.external_dns.extra_args : {
      name  = "extraArgs[${key}]"
      value = value
    }
  ]

  # Combine base set with extra_args
  external_dns_set = concat([
    {
      name  = "txt_owner_id"
      value = var.nuon_id
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.external_dns_irsa.iam_role_arn
    },
    {
      name  = "domain_filters[0]"
      value = local.internal_domain
    },
    {
      name  = "domain_filters[1]"
      value = local.public_domain
    }
  ], local.extra_args_set)
}


module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "external-dns-${var.nuon_id}"

  attach_external_dns_policy = true
  external_dns_hosted_zone_arns = [
    aws_route53_zone.internal.arn,
    aws_route53_zone.public.arn,
  ]

  oidc_providers = {
    ex = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${local.external_dns.namespace}:external-dns"]
    }
  }

  tags = var.tags
}

resource "helm_release" "external_dns" {
  namespace        = local.external_dns.namespace
  create_namespace = true

  name       = local.external_dns.name
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.12.0"

  set = local.external_dns_set

  values = [
    file(local.external_dns.value_file),
  ]

  depends_on = [
    module.external_dns_irsa,
  ]
}

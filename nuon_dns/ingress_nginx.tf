locals {
  ingress_nginx = {
    namespace = "ingress-nginx"
    name      = "ingress-nginx"
  }
}

resource "helm_release" "ingress_nginx" {
  namespace        = local.ingress_nginx.namespace
  create_namespace = true

  name       = local.ingress_nginx.name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.1"
  timeout    = 600

  set = [
    {
      name  = "rbac.create"
      value = "true"
    },
    # The admission webhook fails-closed on deprovision: the controller pod
    # terminates before the webhook can validate deletion of its own remaining
    # resources, so `helm uninstall` hangs until destroy times out, unless
    # this is set.
    {
      name  = "controller.admissionWebhooks.enabled"
      value = "false"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
      value = "internet-facing"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-subnets"
      value = join("\\,", var.public_subnet_ids)
    },
  ]

  depends_on = [
    helm_release.alb_ingress_controller
  ]
}

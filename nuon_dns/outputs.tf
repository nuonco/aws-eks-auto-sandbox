output "public_domain" {
  value = {
    nameservers = aws_route53_zone.public.name_servers
    name        = aws_route53_zone.public.name
    zone_id     = aws_route53_zone.public.id
  }
}

output "internal_domain" {
  value = {
    nameservers = aws_route53_zone.internal.name_servers
    name        = aws_route53_zone.internal.name
    zone_id     = aws_route53_zone.internal.id
  }
}

output "external_dns" {
  value = {
    enabled = true
    release = {
      id        = helm_release.external_dns.id
      namespace = helm_release.external_dns.metadata.namespace
      name      = helm_release.external_dns.metadata.name
      chart     = helm_release.external_dns.metadata.chart
      revision  = helm_release.external_dns.metadata.revision
    }
  }
}

output "cert_manager" {
  value = {
    enabled = true
    release = {
      id        = helm_release.cert_manager.id
      namespace = helm_release.cert_manager.metadata.namespace
      name      = helm_release.cert_manager.metadata.name
      chart     = helm_release.cert_manager.metadata.chart
      revision  = helm_release.cert_manager.metadata.revision
    }
  }
}

output "ingress_nginx" {
  value = {
    enabled = true
    release = {
      id        = helm_release.ingress_nginx.id
      namespace = helm_release.ingress_nginx.metadata.namespace
      name      = helm_release.ingress_nginx.metadata.name
      chart     = helm_release.ingress_nginx.metadata.chart
      revision  = helm_release.ingress_nginx.metadata.revision
    }
  }
}

output "alb_ingress_controller" {
  value = {
    enabled = true
    release = {
      id        = helm_release.alb_ingress_controller.id
      namespace = helm_release.alb_ingress_controller.metadata.namespace
      name      = helm_release.alb_ingress_controller.metadata.name
      chart     = helm_release.alb_ingress_controller.metadata.chart
      revision  = helm_release.alb_ingress_controller.metadata.revision
    }
  }
}

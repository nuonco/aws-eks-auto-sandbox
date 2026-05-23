data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    visibility               = "public"
    "install.nuon.co/id"     = var.nuon_id
    "network.nuon.co/domain" = "public"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    visibility               = "private"
    "network.nuon.co/domain" = "internal"
    "install.nuon.co/id"     = var.nuon_id
  }
}

data "aws_subnets" "runner" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    visibility               = "private"
    "network.nuon.co/domain" = "runner"
    "install.nuon.co/id"     = var.nuon_id
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.key
}


data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.key
}

data "aws_subnet" "runner" {
  for_each = toset(data.aws_subnets.runner.ids)
  id       = each.key
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.vpc.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_security_groups" "runner" {
  tags = {
    "network.nuon.co/domain" = "runner"
    "install.nuon.co/id"     = var.nuon_id
  }
}


locals {
  _private_ids_override = var.private_subnet_ids != "" ? [for s in split(",", var.private_subnet_ids) : trimspace(s)] : []
  _public_ids_override  = var.public_subnet_ids != "" ? [for s in split(",", var.public_subnet_ids) : trimspace(s)] : []
  _runner_ids_override  = var.runner_subnet_id != "" ? [trimspace(var.runner_subnet_id)] : []

  subnets = {
    private = {
      ids   = length(local._private_ids_override) > 0 ? local._private_ids_override : data.aws_subnets.private.ids
      cidrs = length(local._private_ids_override) > 0 ? [for id in local._private_ids_override : data.aws_subnet.private_by_id[id].cidr_block] : values(data.aws_subnet.private)[*].cidr_block
    }
    public = {
      ids   = length(local._public_ids_override) > 0 ? local._public_ids_override : data.aws_subnets.public.ids
      cidrs = length(local._public_ids_override) > 0 ? [for id in local._public_ids_override : data.aws_subnet.public_by_id[id].cidr_block] : values(data.aws_subnet.public)[*].cidr_block
    }
    runner = {
      ids   = length(local._runner_ids_override) > 0 ? local._runner_ids_override : data.aws_subnets.runner.ids
      cidrs = length(local._runner_ids_override) > 0 ? [for id in local._runner_ids_override : data.aws_subnet.runner_by_id[id].cidr_block] : values(data.aws_subnet.runner)[*].cidr_block
    }
  }
}

data "aws_subnet" "private_by_id" {
  for_each = toset(local._private_ids_override)
  id       = each.key
}

data "aws_subnet" "public_by_id" {
  for_each = toset(local._public_ids_override)
  id       = each.key
}

data "aws_subnet" "runner_by_id" {
  for_each = toset(local._runner_ids_override)
  id       = each.key
}

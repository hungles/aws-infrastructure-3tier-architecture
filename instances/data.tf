locals {
  # Selecciona el bucket del mapa usando var.environment
  # Sintaxis: lookup(mapa, llave, valor_por_defecto_opcional)
  selected_bucket = lookup(var.remote_state_buckets, var.environment, var.remote_state_buckets["dev"])
}

# 1. Leer el estado remoto de la red desde S3
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = local.selected_bucket
    key    = var.remote_state_key
    region = var.aws_region
  }
}

# 2. Obtener todas las subredes privadas usando el VPC ID del state
data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    # Cambiamos var.vpc_id por el output del remote state:
    values = [data.terraform_remote_state.network.outputs.vpc_id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]
  }
}

# 3. Obtener todas las subredes públicas usando el VPC ID del state
data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    # Cambiamos var.vpc_id por el output del remote state:
    values = [data.terraform_remote_state.network.outputs.vpc_id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# 4. Detalles de subredes privadas
data "aws_subnet" "private_details" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

# 5. Detalles de subredes públicas
data "aws_subnet" "public_details" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}
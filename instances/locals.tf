# Leer todos los archivos de configuración JSON desde el directorio instances_config
locals {
  # Lee todos los archivos .json del directorio instances_config
  instance_configs_raw = {
    for file in fileset("${path.module}/instances_config", "*.json") :
    trimsuffix(file, ".json") => jsondecode(file("${path.module}/instances_config/${file}"))
  }

  # Combinar subredes privadas y públicas en listas
  private_subnet_ids = data.aws_subnets.private.ids
  public_subnet_ids  = data.aws_subnets.public.ids

  # Procesar configuraciones y asignar subredes dinámicamente
  instance_configs = {
    for name, config in local.instance_configs_raw :
    name => {
      instance_type       = config.instance_type
      is_private          = try(config.is_private, true)
      root_volume_size    = try(config.root_volume_size, 20)
      root_volume_type    = try(config.root_volume_type, "gp3")
      tags                = try(config.tags, {})
      security_group_name = try(config.security_group_name, "sg-app")
      # Asignar subred rotando entre disponibles
      subnet_id = (
        try(config.is_private, true) == true
        ? local.private_subnet_ids[index(sort(keys(local.instance_configs_raw)), name) % length(local.private_subnet_ids)]
        : local.public_subnet_ids[index(sort(keys(local.instance_configs_raw)), name) % length(local.public_subnet_ids)]
      )
    }
  }

  # Combinar tags por defecto con tags personalizados
  default_tags = {
    ManagedBy = "Terraform"
    CreatedAt = timestamp()
  }
}

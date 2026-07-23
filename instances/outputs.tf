# Outputs para cada instancia creada
output "instance_details" {
  description = "Detalles de todas las instancias creadas"
  value = {
    for name, instance_config in local.instance_configs :
    name => {
      instance_type = instance_config.instance_type
      subnet_id     = instance_config.subnet_id
      is_private    = instance_config.is_private
      region_type   = instance_config.is_private ? "Privada" : "Pública"
    }
  }
}

output "instances_map" {
  description = "Nombres de las instancias creadas (keys para referencia)"
  value       = keys(local.instance_configs)
}

output "config_summary" {
  description = "Resumen de la configuración de todas las instancias"
  value = {
    total_instances = length(local.instance_configs)
    private_count   = length([for cfg in local.instance_configs : cfg if cfg.is_private])
    public_count    = length([for cfg in local.instance_configs : cfg if !cfg.is_private])
    subnets_used = {
      private = local.private_subnet_ids
      public  = local.public_subnet_ids
    }
  }
}

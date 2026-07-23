output "vpc_id" {
  description = "El ID de la VPC creada"
  value       = module.vpc_dev.vpc_id
}

output "subnet_ids" {
  description = "Lista de IDs de las subnets públicas"
  value       = module.vpc_dev.public_subnet_ids
}
output "vpc_id" {
  description = "El ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Lista de IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}
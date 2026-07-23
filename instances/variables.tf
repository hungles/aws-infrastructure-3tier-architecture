variable "vpc_id" {
  description = "ID de la VPC donde se crearán los recursos"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (dev, staging, prod)"
  type        = string
  default     = "dev"
}
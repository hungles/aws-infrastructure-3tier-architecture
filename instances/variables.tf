variable "vpc_id" {
  description = "ID de la VPC donde se crearán los recursos"
  type        = string
  default     = "vpc-0056dd43bdc7857ce"
}

variable "environment" {
  description = "Nombre del entorno (dev, staging, prod)"
  type        = string
  default     = "dev"
}
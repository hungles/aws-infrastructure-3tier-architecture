variable "environment" {
  description = "Nombre del entorno (dev, staging, prod)"
  type        = string
}

variable "remote_state_bucket" {
  description = "Nombre del bucket S3 para el remote state de network"
  type        = string
}

variable "remote_state_key" {
  description = "Clave del remote state de network en S3"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}
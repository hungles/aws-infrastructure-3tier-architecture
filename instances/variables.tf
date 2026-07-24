variable "environment" {
  description = "Nombre del entorno (dev, prod)"
  type        = string
}

variable "remote_state_buckets" {
  type        = map(string)
  description = "Mapa de buckets de S3 por ambiente"
  default = {
    "dev" = "hungles-terraform-states-devv"
    "prd" = "hungles-terraform-states-prod"
  }
}

variable "remote_state_key" {
  description = "S3 Remote state key"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}
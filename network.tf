# ------------------------------------------------------------------------------
# Configuración del Módulo de VPC Segura
# ------------------------------------------------------------------------------
module "vpc_dev" {
  source  = "app.terraform.io/hungles_terraform/secure-vpc/aws"
  version = "0.0.2"

  environment = "dev"
  vpc_cidr    = var.vpc_cidr

  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  # Habilitamos un solo NAT Gateway para ahorrar costos en desarrollo
  enable_single_nat_gateway = true

  # Tags organizacionales
  tags = {
    Project    = "SecureInfrastructure"
    Owner      = "DevOpsTeam"
    CostCenter = "101-R&D"
  }
}

module "app_servers" {
  source   = "app.terraform.io/hungles_terraform/ec2_Instance/aws"
  version  = "0.0.2"
  for_each = local.instance_configs

  environment   = var.environment
  instance_type = each.value.instance_type
  vpc_id        = data.terraform_remote_state.network.outputs.vpc_id

  subnet_ids          = [each.value.subnet_id]
  security_group_name = each.value.security_group_name
  ssh_allowed_cidr    = "0.0.0.0/0"
}
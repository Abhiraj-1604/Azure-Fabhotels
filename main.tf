module "network" {
  source                          = "./modules/networking"
  environment                     = var.environment
  project                         = var.project
  address_space                   = var.address_space
  location                        = var.location
  region                          = var.region
  private_subnet_address_prefixes = var.private_subnet_address_prefixes
  public_subnet_address_prefixes  = var.public_subnet_address_prefixes
}

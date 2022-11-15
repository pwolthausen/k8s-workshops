module "k8s_workshop_project" {
  source                  = "terraform-google-modules/project-factory/google"
  version                 = "~> 11.1"
  random_project_id       = "true"
  default_service_account = "deprivilege"
  name                    = "k8s-workshop"
  org_id                  = var.org_id
  billing_account         = var.billing_account
  folder_id               = var.folder_id
  activate_apis = [
    "billingbudgets.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "container.googleapis.com"
  ]

  labels = {
    environment = "k8s-workshop"
  }
}

module "primary_network" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "~> 3.4"
  project_id                             = module.k8s_workshop.project_id
  network_name                           = "k8s-debugging-primary"
  shared_vpc_host                        = "false"
  delete_default_internet_gateway_routes = "true"

  subnets = {}
}

module "secondary_network" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "~> 3.4"
  project_id                             = module.k8s_workshop.project_id
  network_name                           = "k8s-debugging-secondary"
  shared_vpc_host                        = "false"
  delete_default_internet_gateway_routes = "true"

  subnets = {}
}

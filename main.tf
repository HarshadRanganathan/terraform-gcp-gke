locals {
  cluster_name           = var.cluster_name
  network_name           = data.terraform_remote_state.vpc.outputs.network_name
  gke_subnet             = one([for subnet in data.terraform_remote_state.vpc.outputs.subnets : subnet if can(regex("gke-nodes", subnet.name))])
  pods_range_name        = one([for range in local.gke_subnet.secondary_ip_range : range.range_name if range.range_name == "gke-pods"])
  svc_range_name         = one([for range in local.gke_subnet.secondary_ip_range : range.range_name if range.range_name == "gke-services"])
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
    source  = "git::https://github.com/tf-module-gcp-gke.git//modules/beta-autopilot-private-cluster?ref=1.0.0"

    project_id                             = var.project_id
    name                                   = "${local.cluster_name}"
    regional                               = true
    region                                 = var.region
    network                                = local.network_name
    subnetwork                             = local.gke_subnet.name
    ip_range_pods                          = local.pods_range_name
    ip_range_services                      = local.svc_range_name
    master_authorized_networks             = var.master_authorized_networks
    release_channel                        = "STABLE"
    enable_vertical_pod_autoscaling        = true
    enable_private_endpoint                = true
    deploy_using_private_endpoint          = true
    enable_private_nodes                   = true
    network_tags                           = [local.cluster_name]
    deletion_protection                    = false
    insecure_kubelet_readonly_port_enabled = false
    maintenance_start_time                 = var.maintenance_start_time
    maintenance_end_time                   = var.maintenance_end_time
    maintenance_recurrence                 = var.maintenance_recurrence
    maintenance_exclusions                 = var.maintenance_exclusions
    notification_config_topic              = "projects/${var.project_id}/topics/${google_pubsub_topic.gke_notifications.name}"
    enable_cost_allocation                 = true
    grant_registry_access                  = true
    cluster_resource_labels                = var.cluster_resource_labels
}
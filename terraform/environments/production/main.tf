resource "google_project_service" "terraform" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sts.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "containerregistry.googleapis.com",
    "artifactregistry.googleapis.com",
    "autoscaling.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerfilesystem.googleapis.com",
    "datastore.googleapis.com",
    "dns.googleapis.com",
    "domains.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "certificatemanager.googleapis.com",
    "secretmanager.googleapis.com",
    "redis.googleapis.com",
    "googleads.googleapis.com",
  ])
  service = each.value
}

module "project_user_iam_bindings" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = [var.project_id]
  mode     = "additive"

  bindings = {
    "roles/viewer" = [
      "group:someservice-developer@someservice.com"
    ]
    "roles/container.admin" = [
      "group:someservice-developer@someservice.com"
    ]
    "roles/secretmanager.secretAccessor" = [
      "group:someservice-developer@someservice.com"
    ]
  }
}

data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_global_address" "default" {
  name          = "default-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.default.id
}

resource "google_service_networking_connection" "default" {
  network                 = data.google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.default.name]
}

resource "google_iam_workload_identity_pool" "oidc_pool" {
  project = var.project_id

  workload_identity_pool_id = "oidc-pool"
  display_name              = "oidc-pool"
  description               = "Workload Identity プール"
  disabled                  = false
}

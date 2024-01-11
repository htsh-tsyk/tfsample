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
    "sheets.googleapis.com",
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
    "roles/bigquery.admin" = [
      "user:kimura@someservice.com",
      "group:someservice-developer@someservice.com"
    ]
    "roles/container.admin" = [
      "group:someservice-developer@someservice.com"
    ]
    "roles/secretmanager.secretAccessor" = [
      "group:someservice-developer@someservice.com"
    ]
    "roles/storage.admin" = [
      "group:someservice-developer@someservice.com"
    ]
    "roles/iam.serviceAccountUser" = [
      "group:someservice-developer@someservice.com"
    ]
    "roles/oauthconfig.editor" = [
      "group:someservice-developer@someservice.com"
    ]
  }
}

resource "google_iam_workload_identity_pool" "oidc_pool" {
  project = var.project_id

  workload_identity_pool_id = "oidc-pool"
  display_name              = "oidc-pool"
  description               = "外部サービスから OIDC 経由で GCP にアクセスするための Workload Identity プール"
  disabled                  = false
}

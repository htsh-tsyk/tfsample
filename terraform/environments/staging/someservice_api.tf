resource "google_service_account" "someservice_api" {
  account_id   = "someservice-api"
  display_name = "someservice-api"
}

resource "google_compute_global_address" "someservice_api" {
  project = var.project_id
  name    = "someservice-api"
}

resource "google_dns_record_set" "someservice_api" {
  name = "someservice-api.${google_dns_managed_zone.someservice.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.someservice.name

  rrdatas = [google_compute_global_address.someservice_api.address]
}

variable "someservice_web_cname" {
  description = "Type CNAME DNS Record value of app.someservice.dev"
  type        = string
}

resource "google_dns_record_set" "someservice_webservice_cname" {
  name = "app.${google_dns_managed_zone.someservice.dns_name}"
  type = "CNAME"
  ttl  = 300

  managed_zone = google_dns_managed_zone.someservice.name

  rrdatas = [var.someservice_web_cname]
}

variable "someservice_api_encryption_key" {
  type = object({
    encryption_primary_key         = string
    encryption_key_derivation_salt = string
  })
  sensitive = true
}

resource "google_secret_manager_secret" "someservice_api_encryption_key" {
  secret_id = "someservice-api-encryption-key"

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.terraform["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "someservice_api_encryption_key" {
  secret      = google_secret_manager_secret.someservice_api_encryption_key.id
  secret_data = "{ \"encryption_primary_key\": \"${var.someservice_api_encryption_key.encryption_primary_key}\", \"encryption_key_derivation_salt\": \"${var.someservice_api_encryption_key.encryption_key_derivation_salt}\" }"
}

variable "someservice_api_db_credential" {
  type = object({
    db_user     = string
    db_password = string
  })
  sensitive = true
}

resource "google_secret_manager_secret" "someservice_api_cloudsql_credential" {
  secret_id = "someservice-api-cloudsql-credential"

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.terraform["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "someservice_api_sql_user_cert" {
  secret      = google_secret_manager_secret.someservice_api_cloudsql_credential.id
  secret_data = "{ \"password\": \"${var.someservice_api_db_credential.db_password}\", \"user_name\": \"${var.someservice_api_db_credential.db_user}\" }"
}

resource "google_service_account_iam_binding" "someservice_api" {
  service_account_id = google_service_account.someservice_api.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[someservice-api/someservice-api-ksa]"
  ]

  depends_on = [google_container_cluster.someservice]
}

resource "google_project_iam_member" "someservice_api" {
  project = var.project_id
  for_each = toset([
    "roles/editor",
    "roles/bigquery.admin",
    "roles/storage.admin",
    "roles/certificatemanager.editor",
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.someservice_api.email}"
}

resource "google_sql_database_instance" "someservice_api" {
  name             = "someservice-someservice-api-staging"
  region           = "asia-northeast1"
  database_version = "POSTGRES_14"

  settings {
    tier = "db-custom-2-8192"

    maintenance_window {
      update_track = "stable"
    }
  }
}

resource "google_sql_database" "someservice_api" {
  name     = "someservice-api_production"
  instance = google_sql_database_instance.someservice_api.name

  deletion_policy = "ABANDON"
}

resource "google_sql_user" "someservice_api" {
  instance = google_sql_database_instance.someservice_api.name
  name     = var.someservice_api_db_credential.db_user
  password = var.someservice_api_db_credential.db_password
}

resource "google_redis_instance" "someservice_api_sidekiq" {
  name           = "someservice-api-sidekiq"
  memory_size_gb = 1
  location_id    = "asia-northeast1-a"
  redis_version  = "REDIS_6_X"
}

variable "someservice_api_slack_api_token" {
  type = string
  sensitive = true
}

resource "google_secret_manager_secret" "someservice_api_slack_api_token" {
  secret_id = "someservice-api-slack-api-token"

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.terraform["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "someservice_api_slack_api_token" {
  secret      = google_secret_manager_secret.someservice_api_slack_api_token.id
  secret_data = var.someservice_api_slack_api_token
}

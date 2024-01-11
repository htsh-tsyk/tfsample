resource "google_service_account" "someservice_workflow" {
  account_id   = "someservice-workflow"
  display_name = "someservice-workflow"
}

resource "google_service_account_iam_binding" "someservice_workflow" {
  service_account_id = google_service_account.someservice_workflow.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[someservice-workflow/someservice-workflow-ksa]"
  ]

  depends_on = [google_container_cluster.someservice]
}

resource "google_project_iam_member" "someservice_workflow" {
  project = var.project_id
  for_each = toset([
    "roles/bigquery.admin",
    "roles/storage.admin",
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.someservice_workflow.email}"
}

resource "google_service_account_key" "someservice_workflow" {
  service_account_id = google_service_account.someservice_workflow.name
}

resource "google_secret_manager_secret" "someservice_workflow_service_account" {
  secret_id = "someservice-workflow-service-account"

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.terraform["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "someservice_workflow_service_account" {
  secret      = google_secret_manager_secret.someservice_workflow_service_account.id
  secret_data = base64decode(google_service_account_key.someservice_workflow.private_key)
}

resource "google_storage_bucket" "someservice_workflow" {
  name     = "someservice_workflow_${var.project_id}"
  location = "asia-northeast1"
}

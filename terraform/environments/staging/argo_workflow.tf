resource "google_service_account" "argo_workflow_server" {
  account_id   = "argo-workflow-server"
  display_name = "argo-workflow-server"
}

resource "google_storage_bucket" "argo_workflow" {
  name     = "argo-workflow_${var.project_id}"
  location = "asia-northeast1"
}

resource "google_compute_global_address" "argo_workflow" {
  project = var.project_id
  name    = "argo-workflow"
}

resource "google_dns_record_set" "argo_workflow" {
  name = "argo-workflow.${google_dns_managed_zone.someservice.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.someservice.name

  rrdatas = [google_compute_global_address.argo_workflow.address]
}

resource "google_project_iam_member" "argo_workflow_server" {
  project = var.project_id
  for_each = toset([
    "roles/storage.objectViewer",
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.argo_workflow_server.email}"
}

resource "google_service_account_iam_binding" "argo_workflow_server" {
  service_account_id = google_service_account.argo_workflow_server.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[argo-workflow/argo-workflow-server-ksa]"
  ]
}

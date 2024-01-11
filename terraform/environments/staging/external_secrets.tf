resource "google_service_account" "external_secrets" {
  account_id   = "secret-manager"
  display_name = "secret-manager"
}

resource "google_service_account_iam_binding" "external_secrets" {
  service_account_id = google_service_account.external_secrets.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets-ksa]"
  ]
}

resource "google_project_iam_member" "external_secrets" {
  project = var.project_id
  for_each = toset([
    "roles/secretmanager.secretAccessor",
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.external_secrets.email}"
}

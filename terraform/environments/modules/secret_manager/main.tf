resource "google_secret_manager_secret" "main" {
  secret_id = var.secret_id

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "main" {
  secret      = google_secret_manager_secret.main.id
  secret_data = var.secret_data
}

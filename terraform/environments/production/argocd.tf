# ------------------------------------------
# ArgoCD 本体
# ------------------------------------------

resource "google_compute_global_address" "argocd" {
  project = var.project_id
  name    = "argocd"
}

resource "google_dns_record_set" "argocd" {
  name = "argocd.${google_dns_managed_zone.someservice.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.someservice.name

  rrdatas = [google_compute_global_address.argocd.address]
}

variable "argo_cd_github_repo" {
  type = object({
    github_app_private_key = string
  })
  sensitive = true
}

resource "google_secret_manager_secret" "argo_cd_github_repo" {
  secret_id = "argo-cd-github-repo"

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.terraform["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "argo_cd_github_repo" {
  secret      = google_secret_manager_secret.argo_cd_github_repo.id
  secret_data = "{ \"github_app_private_key\": \"${var.argo_cd_github_repo.github_app_private_key}\" }"
}

variable "argo_cd_dex_github" {
  type = string

  sensitive = true
}

resource "google_secret_manager_secret" "argo_cd_dex_github" {
  secret_id = "argo-cd-dex-github"

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.terraform["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "argo_cd_dex_github" {
  secret      = google_secret_manager_secret.argo_cd_dex_github.id
  secret_data = var.argo_cd_dex_github
}

# ------------------------------------------
# ArgoCD image updater
# ------------------------------------------

resource "google_service_account" "argocd_image_updater" {
  account_id   = "argocd-image-updater"
  display_name = "argocd-image-updater"
}

resource "google_project_iam_member" "argocd_image_updater" {
  project = var.project_id
  for_each = toset([
    "roles/storage.objectViewer",
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.argocd_image_updater.email}"
}

resource "google_service_account_key" "argocd_image_updater" {
  service_account_id = google_service_account.argocd_image_updater.name
}

resource "google_secret_manager_secret" "argocd_image_updater_gcr_credential" {
  secret_id = "argocd-image-updater-gcr-credential"

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.terraform["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "argocd_image_updater_gcr_credential" {
  secret = google_secret_manager_secret.argocd_image_updater_gcr_credential.id
  secret_data = jsonencode({
    auths = {
      "https://gcr.io" = {
        username = "_json_key"
        password = base64decode(google_service_account_key.argocd_image_updater.private_key)
        email    = google_service_account.argocd_image_updater.email
        auth     = base64encode("_json_key:${base64decode(google_service_account_key.argocd_image_updater.private_key)}")
      }
    }
  })
}

variable "argocd_image_updater_token" {
  type = string

  sensitive = true
}

resource "google_secret_manager_secret" "argocd_image_updater_token" {
  secret_id = "argocd-image-updater-token"

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.terraform["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "argocd_image_updater_token" {
  secret      = google_secret_manager_secret.argocd_image_updater_token.id
  secret_data = var.argocd_image_updater_token
}

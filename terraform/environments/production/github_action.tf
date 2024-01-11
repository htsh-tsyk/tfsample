resource "google_iam_workload_identity_pool_provider" "github_actions_oidc" {
  project = var.project_id

  workload_identity_pool_id          = google_iam_workload_identity_pool.oidc_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-oidc"
  display_name                       = "github-actions-oidc"
  description                        = "GitHub Actions 用Workload Identity プロバイダ"
  disabled                           = false
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.aud"        = "assertion.aud"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    # NOTE: allowed_audiences はデフォルトだと workload_identity_pool_provider の ID になる
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ------------------------------------------
# GitHub Actions　for someservice-manifests
# ------------------------------------------

resource "google_service_account" "github_actions" {
  account_id   = "github-actions"
  display_name = "github-actions"
}

module "terraform_gh_oidc" {
  source      = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  project_id  = var.project_id
  pool_id     = "terraform-pool"
  provider_id = "terraform-gh-provider"
  sa_mapping = {
    "terraform" = {
      sa_name   = google_service_account.terraform.name
      attribute = "attribute.repository/someorg/someservice-manifests"
    }
  }
}

# ------------------------------------------
# GitHub Actions for someservice-source
# ------------------------------------------

resource "google_service_account" "release" {
  account_id   = "release"
  display_name = "release"
}

resource "google_project_iam_member" "release" {
  project = var.project_id
  for_each = toset([
    "roles/storage.admin",
    "roles/cloudbuild.builds.builder",
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.release.email}"
}

resource "google_service_account_iam_member" "release_sa_can_access_someservice_source_repository" {
  service_account_id = google_service_account.release.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.oidc_pool.name}/attribute.repository/someorg/someservice-source"

  depends_on = [
    google_service_account.release,
  ]
}

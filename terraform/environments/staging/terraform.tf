resource "google_storage_bucket" "terraform_state_store" {
  name     = var.terraform_bucket
  location = var.region
}

resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "terraform"
}

resource "google_project_iam_member" "terraform" {
  project = var.project_id
  count   = length(var.terraform_sa_roles)
  role    = element(var.terraform_sa_roles, count.index)
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

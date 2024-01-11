variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "GCP default region"
  type        = string
}

variable "zone" {
  description = "GCP default zone"
  type        = string
}

variable "terraform_bucket" {
  description = "The name of your bucket to store the state file. Case-sensitive."
  type        = string
}

variable "terraform_sa_roles" {
  description = "Terraform SA Roles"
  type        = list(string)
  default = [
    "roles/editor",
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/secretmanager.admin",
    "roles/compute.networkAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
  ]
}

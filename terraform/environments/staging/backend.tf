terraform {
  backend "gcs" {
    bucket = "terraform_someservice-staging"
    prefix = "terraform/state"
  }
}

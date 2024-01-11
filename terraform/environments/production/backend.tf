terraform {
  backend "gcs" {
    bucket = "someservice-production"
    prefix = "terraform/state"
  }
}

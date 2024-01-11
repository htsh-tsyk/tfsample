tfmigrate {
  migration_dir = "./tfmigrate"
  history {
    storage "gcs" {
      bucket = "terraform_someservice-staging"
      name   = "tfmigrate/history.json"
    }
  }
}

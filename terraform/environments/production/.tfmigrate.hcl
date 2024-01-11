tfmigrate {
  migration_dir = "./tfmigrate"
  history {
    storage "gcs" {
      bucket = "terraform_someservice-production"
      name   = "tfmigrate/history.json"
    }
  }
}

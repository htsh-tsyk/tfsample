
resource "google_container_cluster" "someservice" {
  name             = "someservice"
  location         = "asia-northeast1"
  enable_autopilot = true

  min_master_version = "1.24.9-gke.3200"

  # If the issue is resolved in the future, remove ip_allocation_policy block below.
  # https://github.com/hashicorp/terraform-provider-google/issues/10782
  ip_allocation_policy {}

  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
}

resource "google_dns_managed_zone" "someservice" {
  description = "ドメインの DNS ゾーン: someservice.com"
  name        = "someservice-com"
  dns_name    = "someservice.com."

  dnssec_config {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"

    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 2048
      key_type   = "keySigning"
      kind       = "dns#dnsKeySpec"
    }
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 1024
      key_type   = "zoneSigning"
      kind       = "dns#dnsKeySpec"
    }
  }
}

resource "google_dns_record_set" "someservice_soa" {
  name = google_dns_managed_zone.someservice.dns_name
  type = "SOA"
  ttl  = 21600

  managed_zone = google_dns_managed_zone.someservice.name

  rrdatas = [
    "ns-cloud-b1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300"
  ]
}

resource "google_dns_record_set" "someservice_ns" {
  name = google_dns_managed_zone.someservice.dns_name
  type = "NS"
  ttl  = 21600

  managed_zone = google_dns_managed_zone.someservice.name

  rrdatas = [
    "ns-cloud-b1.googledomains.com.",
    "ns-cloud-b2.googledomains.com.",
    "ns-cloud-b3.googledomains.com.",
    "ns-cloud-b4.googledomains.com."
  ]
}

resource "google_certificate_manager_dns_authorization" "someservice" {
  name        = "cm-someservice"
  description = "cm-someservice"
  domain      = "someservice.com"
}

resource "google_certificate_manager_certificate" "someservice" {
  name        = "someservice-managed-cert"
  description = "someservice-managed-cert"
  managed {
    domains = [
      "*.${google_certificate_manager_dns_authorization.someservice.domain}",
    ]
    dns_authorizations = [google_certificate_manager_dns_authorization.someservice.id]
  }
}

resource "google_certificate_manager_certificate_map" "someservice" {
  name        = "someservice-managed-cert-map"
  description = "someservice-managed-cert-map"
}

resource "google_certificate_manager_certificate_map_entry" "someservice" {
  name         = "someservice-cert-map-entry"
  description  = "someservice-cert-map-entry"
  map          = google_certificate_manager_certificate_map.someservice.name
  certificates = [google_certificate_manager_certificate.someservice.id]
  hostname     = "*.${google_certificate_manager_dns_authorization.someservice.domain}"
}

resource "google_dns_record_set" "someservice_cname" {
  name = google_certificate_manager_dns_authorization.someservice.dns_resource_record.0.name
  type = "CNAME"
  ttl  = 300

  managed_zone = google_dns_managed_zone.someservice.name

  rrdatas = [
    google_certificate_manager_dns_authorization.someservice.dns_resource_record.0.data
  ]
}


variable "google_ads_developer_credentials" {
  type = string

  sensitive = true
}

resource "google_secret_manager_secret" "google_ads_developer_credentials" {
  secret_id = "google-ads-developer-credentials"

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }

  depends_on = [google_project_service.terraform["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "google_ads_developer_credentials" {
  secret      = google_secret_manager_secret.google_ads_developer_credentials.id
  secret_data = var.google_ads_developer_credentials
}

variable "yahoo_offline_conversion_developer_credentials" {
  type = string

  sensitive = true
}

module "yahoo_offline_conversion_developer_credentials" {
  source      = "../modules/secret_manager"
  secret_id   = "yahoo-offline-conversion-developer-credentials"
  secret_data = var.yahoo_offline_conversion_developer_credentials
}


resource "google_monitoring_notification_channel" "someorg_slack" {
  for_each = toset([
    "#monitoring-someservice-error-staging",
  ])

  display_name = "someorg ${each.value}"
  type         = "slack"
  labels = {
    auth_token   = ""
    team         = "Someorg"
    channel_name = each.value
  }

  timeouts {}
}

# ------------------------------------------
# someservice API Monitoring
# ------------------------------------------

resource "google_monitoring_uptime_check_config" "someservice_api" {
  display_name     = "health check someservice-api.someservice.dev"
  timeout          = "10s"
  period           = "60s"
  selected_regions = []

  http_check {
    request_method = "GET"
    path           = "/"
    port           = "443"
    use_ssl        = true
    validate_ssl   = true
    mask_headers   = false

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
      status_value = 0
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "someservice-staging"
      host       = "someservice-api.someservice.dev"
    }
  }
}

resource "google_monitoring_alert_policy" "someservice_api_helth_check" {
  display_name = "health check someservice-api.someservice.dev uptime failure"
  combiner     = "OR"

  notification_channels = [
    google_monitoring_notification_channel.someorg_slack["#monitoring-someservice-error-staging"].name,
  ]

  alert_strategy {
    auto_close = "604800s"
  }

  conditions {
    display_name = "Failure of uptime check_id health-check-someservice-api-someservice-dev"

    condition_threshold {
      filter          = "resource.type = \"uptime_url\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.labels.check_id = \"${google_monitoring_uptime_check_config.someservice_api.uptime_check_id}\""
      threshold_value = 1
      duration        = "60s"
      comparison      = "COMPARISON_GT"

      aggregations {
        alignment_period     = "1200s"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields = [
          "resource.label.project_id",
          "resource.label.host",
        ]
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  timeouts {}
}

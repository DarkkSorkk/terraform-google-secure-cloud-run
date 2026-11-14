# Two alerts that catch the expensive surprises early: a traffic spike (an attack, a loop in a client, a
# crawler) and a burst of server errors. Created only when notification channels are given.

locals {
  alerts_enabled = length(var.notification_channels) > 0

  run_filter = join(" AND ", [
    "resource.type = \"cloud_run_revision\"",
    "resource.labels.service_name = \"${var.name}\"",
    "metric.type = \"run.googleapis.com/request_count\"",
  ])
}

resource "google_monitoring_alert_policy" "request_spike" {
  count = local.alerts_enabled ? 1 : 0

  project               = var.project_id
  display_name          = "${var.name}: request spike"
  combiner              = "OR"
  notification_channels = var.notification_channels
  user_labels           = var.labels

  conditions {
    display_name = "More than ${var.alert_requests_per_5min} requests in 5 minutes"

    condition_threshold {
      filter          = local.run_filter
      comparison      = "COMPARISON_GT"
      threshold_value = var.alert_requests_per_5min
      duration        = "0s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "Traffic on **${var.name}** is far above normal. Check the request logs for the source. If it is abuse, remove public access (`roles/run.invoker` for `allUsers`) until it stops: max_instances already caps the bill, but not the noise."
  }

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "server_errors" {
  count = local.alerts_enabled ? 1 : 0

  project               = var.project_id
  display_name          = "${var.name}: server errors"
  combiner              = "OR"
  notification_channels = var.notification_channels
  user_labels           = var.labels

  conditions {
    display_name = "More than ${var.alert_5xx_per_5min} HTTP 5xx in 5 minutes"

    condition_threshold {
      filter          = "${local.run_filter} AND metric.labels.response_code_class = \"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.alert_5xx_per_5min
      duration        = "0s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "**${var.name}** is returning server errors. Check the latest revision and its logs. To roll back: `gcloud run services update-traffic ${var.name} --region=${var.region} --to-revisions=PREVIOUS_REVISION=100`."
  }

  alert_strategy {
    auto_close = "1800s"
  }
}

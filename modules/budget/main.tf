# A monthly budget for one project, with alerts on actual spend and on the month's forecast.
#
# A budget is an alarm, not a cap: Google keeps billing after 100%. The caps are in the service itself
# (max_instances, concurrency, CPU only during requests). For an automatic response, send the budget to a
# Pub/Sub topic (pubsub_topic) and act on it.

data "google_project" "this" {
  project_id = var.project_id
}

resource "google_billing_budget" "this" {
  billing_account = var.billing_account
  display_name    = var.display_name

  budget_filter {
    projects        = ["projects/${data.google_project.this.number}"]
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = var.currency_code
      units         = tostring(var.amount)
    }
  }

  dynamic "threshold_rules" {
    for_each = var.thresholds

    content {
      threshold_percent = threshold_rules.value
      spend_basis       = "CURRENT_SPEND"
    }
  }

  dynamic "threshold_rules" {
    for_each = var.forecast_threshold == null ? [] : [var.forecast_threshold]

    content {
      threshold_percent = threshold_rules.value
      spend_basis       = "FORECASTED_SPEND"
    }
  }

  all_updates_rule {
    monitoring_notification_channels = var.notification_channels
    pubsub_topic                     = var.pubsub_topic
    schema_version                   = var.pubsub_topic == null ? null : "1.0"
    disable_default_iam_recipients   = var.disable_default_iam_recipients
  }
}
